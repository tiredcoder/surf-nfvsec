CREATE TABLE edu (id     INTEGER  NOT NULL  PRIMARY KEY,
                  name   TEXT     NOT NULL             ,
                  ip     TEXT     NOT NULL             
                 );

CREATE TABLE vnf (id     INTEGER  NOT NULL  PRIMARY KEY,
                  class  TEXT     NOT NULL             ,
                  ip     TEXT     NOT NULL             
                 );

CREATE TABLE rules (id     INTEGER  NOT NULL  PRIMARY KEY,
                    edu     TEXT     NOT NULL            ,
                    vnf     TEXT     NOT NULL             
                   );
