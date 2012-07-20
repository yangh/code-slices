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
from google.appengine.ext import webapp
from google.appengine.ext.webapp import util

from dnscache import DNSCacheManager
from config import DNSConfig

import logging

class CleanOldCacheHandler(webapp.RequestHandler):
    def get(self):
        conf = DNSConfig()
        cm = DNSCacheManager()
        logging.debug("Start clean old cache...")
        cm.delete_old_cache(conf.cache_cron_life)
        return

def main():
    application = webapp.WSGIApplication([('/cron/cleancache', CleanOldCacheHandler)],
                                         debug=True)
    util.run_wsgi_app(application)


if __name__ == '__main__':
    main()
