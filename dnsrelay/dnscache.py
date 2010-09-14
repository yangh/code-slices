#!/usr/bin/env python
#
# Copyright 2010 pen9u1n
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from google.appengine.ext import db
from google.appengine.runtime.apiproxy_errors import CapabilityDisabledError
from datetime import datetime
from dns import Host

import logging

class HostCache(Host):
    hit = db.IntegerProperty()
    failed = db.IntegerProperty()
    create_date = db.DateTimeProperty(auto_now_add=True)
    update_date = db.DateTimeProperty(auto_now_add=True)

class DNSCacheManager(object):
    def update(self, domain, ip, hit = True):
        updated = False
        hosts = db.GqlQuery("SELECT * FROM HostCache WHERE domain = :1 LIMIT 1", domain)
        for host in hosts:
            if hit:
                host.hit += 1
            else:
                host.failed +=1

            if (len(host.ip) < 2):
                host.ip = ip
            host.update_date = datetime.utcnow()

            try:
                db.put(host)
                updated = True
            except CapabilityDisabledError:
                return

        if updated:
            return

        # Add new entity
        h = 1
        f = 0
        if (not hit):
            h = 0
            f = 1

        host = HostCache(ip = ip, domain = domain, hit = h, failed = f)
        try:
            host.put()
        except CapabilityDisabledError:
            pass

        return

    def get(self, domain):
        hosts = db.GqlQuery("SELECT * FROM HostCache WHERE domain = :1 LIMIT 1", domain)
        for host in hosts:
            return host

        return null

def main():
    print "Do some test here."

if __name__ == '__main__':
    main()
