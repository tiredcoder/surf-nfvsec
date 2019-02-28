When using version 5 (upcomming release) of rqlite, we need to change the client python lib to handle connections to cluster slave nodes. See:
https://github.com/rqlite/pyrqlite/issues/19
https://github.com/zmedico/pyrqlite/commit/5661992e3ba98b860eefc1983c93ad0e06b8650d

git clone commit f8cd41e0522af36a234088b3c876ccfc5078f662 from the master branch from https://github.com/rqlite/pyrqlite and apply the changes from zmedico to ./src/pyrqlite/connections.py.
