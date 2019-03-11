#!/usr/bin/env python3
#
# SURF NFV Controller
# Author: Rik Janssen <Rik.Janssen@os3.nl>
#
# Project: UvA, SNE/OS3, RP2
# Version: 1.1, Mar. 2019
# Dependencies:
#  Flask (v1.0.2)
#  rqlite (v5, master branch, commit 4f9965d20aff6d03521c2b70d3514516a9b5251f)
#  pyrqlite (master branch, commit f8cd41e0522af36a234088b3c876ccfc5078f662 and using patch from https://github.com/zmedico/pyrqlite/commit/5661992e3ba98b860eefc1983c93ad0e06b8650d)
#
# Set the env var 'DBSERV' to the name or IP address of the database server/cluster.
#
# Uses code snippets from:
#  http://flask.pocoo.org/snippets/
#  http://flask.pocoo.org/docs/1.0/patterns/sqlite3/
#
# SECURITY WARNING: This application is just a proof of concept and doesn't do any authentication, encryption, or error checking! SQL injection might also be possible!
#
# Create database (use curl or below commands):
#  export FLASK_APP=nfv_controller.py
#  flask initdb
#
# Start: ./nfv_controller.py
# Manual: See curl.txt and /about
#
from flask import Flask, request, render_template, json, g
from pyrqlite import dbapi2 as rqlite
from os import environ as osenv
import subprocess

print(" * SURF NFV Controller")
database_server = osenv.get('DBSERV', 'localhost')
print(" * Database server: " + database_server + " (rqlite)")
nfvctrl = Flask(__name__)


# Database functions

# Close database connection when closing app
@nfvctrl.teardown_appcontext
def teardown_db(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

# Get current database connection or create a new one
def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = rqlite.connect(host=database_server, port=4001)
    return db

# Initialize the database (create the tables)
def init_db():
    with nfvctrl.app_context():
        cur = get_db().cursor()
        with nfvctrl.open_resource('schema.sql', mode='r') as f:
            cur.execute(f.read())
        get_db().commit()
        cur.connection.close()

@nfvctrl.cli.command('initdb')
def initdb_command():
    """Initializes the database."""
    init_db()
    print('Initialized the database.')

# Flush the database (removes all tables)
def flush_db():
    tables = ['edu', 'vnf', 'rules']
    cur = get_db().cursor()
    for table in tables:
        query = 'DROP TABLE %s' % (table)
        cur.execute(query)
    get_db().commit()
    cur.connection.close()

# Query the database
def query_db(query, args=(), one=False):
    cur = get_db().cursor()
    cur.execute(query, args)
    rv = [dict((cur.description[idx][0], value)
               for idx, value in enumerate(row)) for row in cur.fetchall()]
    cur.connection.close()
    return (rv[0] if rv else None) if one else rv

# Insert values into the database
def insert_db(table, fields=(), values=()):
    query = 'INSERT INTO %s (%s) VALUES (%s)' % (
        table,
        ', '.join(fields),
        ', '.join(['?'] * len(values))
    )
    cur = get_db().cursor()
    cur.execute(query, values)
    get_db().commit()
    id = cur.lastrowid
    cur.connection.close()
    return id

# Delete value from the database
def delete_db(table, id):
    query = 'DELETE FROM %s WHERE id=%s' % (table, id)
    cur = get_db().cursor()
    cur.execute(query)
    res = get_db().commit()
    cur.connection.close()
    return id


# Load balancer functions

# Create or remove rule
def ctrl_infra(cmd, edu, vnf):
  subprocess.run(["/bin/bash", "/surf/app/infra-ctrl.sh", cmd, edu, vnf])


# Routes

# Show general info about the web app
@nfvctrl.route('/', methods = ['GET'])
def about():
    return render_template("about.html")

# Show manual
@nfvctrl.route('/api', methods = ['GET'])
def api():
    return render_template("curl.txt")

# Create the database (creates the tables)
@nfvctrl.route('/api/db/init', methods = ['PUT'])
def api_initdb():
    init_db()
    return "Database initialized."

# Flush the database (remove all tables)
@nfvctrl.route('/api/db/flush', methods = ['PUT'])
def api_flushdb():
    flush_db()
    return "Database flushed: all tables have been removed."

# Show all VNFs or create a new one
@nfvctrl.route('/api/vnf', methods = ['GET', 'PUT'])
def mutate_vnfs():
    if request.method == 'GET':
        vnfs = query_db('SELECT * FROM vnf')
        return json.dumps(vnfs)
    if request.method == 'PUT':
        if request.headers['Content-Type'] == 'application/json':
            data = request.get_json()
            vnf = insert_db('vnf', ('class','ip'), (data['class'], data['ip']))
            return json.dumps(vnf)
        else:
            return '415 Unsupported Media Type'

# Show all edu. institutions or create a new one
@nfvctrl.route('/api/edu', methods = ['GET', 'PUT'])
def mutate_edus():
    if request.method == 'GET':
        edus = query_db('SELECT * FROM edu')
        return json.dumps(edus)
    if request.method == 'PUT':
        if request.headers['Content-Type'] == 'application/json':
            data = request.get_json()
            edu = insert_db('edu', ('name','ip'), (data['name'], data['ip']))
            return json.dumps(edu)
        else:
            return '415 Unsupported Media Type'

# Show or delete VNF
@nfvctrl.route('/api/vnf/<vnfid>', methods = ['GET', 'DELETE'])
def mutate_vnf(vnfid):
    if request.method == 'GET':
        vnf = query_db('SELECT * FROM vnf WHERE id = ?', vnfid, one=True)
        return json.dumps(vnf)
    if request.method == 'DELETE':
        vnf = delete_db('vnf', vnfid)
        return json.dumps(vnf)

# Show or delete edu
@nfvctrl.route('/api/edu/<eduid>', methods = ['GET', 'DELETE'])
def mutate_edu(eduid):
    if request.method == 'GET':
        edu = query_db('SELECT * FROM edu WHERE id = ?', eduid, one=True)
        return json.dumps(edu)
    if request.method == 'DELETE':
        edu = delete_db('edu', eduid)
        return json.dumps(edu)

# Show all rules or create a new rule
@nfvctrl.route('/api/rules', methods = ['GET', 'PUT'])
def mutate_rules():
    if request.method == 'GET':
        rules = query_db('SELECT * FROM rules')
        return json.dumps(rules)
    if request.method == 'PUT':
        if request.headers['Content-Type'] == 'application/json':
            data = request.get_json()
            rule = insert_db('rules', ('edu','vnf'), (data['edu_ip'], data['vnf_ip']))
            ctrl_infra('add', data['edu_ip'], data['vnf_ip'])
            return json.dumps(rule)
        else:
            return '415 Unsupported Media Type'

# Show or delete a single rule
@nfvctrl.route('/api/rules/<ruleid>', methods = ['GET', 'DELETE'])
def mutate_rule(ruleid):
    if request.method == 'GET':
        rule = query_db('SELECT * FROM rules WHERE id = ?', ruleid, one=True)
        return json.dumps(rule)
    if request.method == 'DELETE':
        res = query_db('SELECT * FROM rules WHERE id = ?', ruleid, one=True)
        rule = delete_db('rules', ruleid)
        ctrl_infra('del', res['edu'], res['vnf'])
        return json.dumps(rule)


# Main
if __name__ == "__main__":
    nfvctrl.run(host='0.0.0.0', port=80)
