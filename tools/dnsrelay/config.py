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

class DNSConfig(object):
    def __init__(self):
        # Hosts
        self.use_hosts = False

        # Cache
        self.cache_web_query = True
        self.use_cache = True          # depends on self.cache_web_query
        self.cache_life = 60 * 60 * 6  # 6 hours

        # Cache life before delete by cron job
        self.cache_cron_life = 60 * 60 * 24 * 7 # 7 days
