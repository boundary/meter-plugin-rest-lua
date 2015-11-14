-- Copyright 2015 BMC Software, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

framework = require('framework')
local Plugin = framework.Plugin
local notEmpty = framework.string.notEmpty
local WebRequestDataSource = framework.WebRequestDataSource
local parseJson = framework.util.parseJson
local ipack = framework.util.ipack

-- Fetch the parameters passed to the plugin
local params = framework.params

params.pollInterval = notEmpty(params.pollInterval, 5000)
params.host = notEmpty(params.host, "127.0.0.1")
params.port = notEmpty(params.port, 5000)
params.protocol = 'http'
params.source = notEmpty(params.source)

-- Set REST call options
local options = {}
options.host = params.host
options.port = params.port
-- options.auth = auth(params.username, params.password)
options.path = "/api/v1/performance"
options.wait_for_end = false

local plugin
local ds = WebRequestDataSource:new(options)

plugin = Plugin:new(params, ds)

-- Define a table to map the source data to the specific
-- metric identifier
local metricMap = {}
metricMap['bytecount'] = 'TSP_REST_METRIC_BYTECOUNT'
metricMap['duration'] = 'TSP_REST_METRIC_DURATION'
metricMap['number'] = 'TSP_REST_METRIC_NUMBER'
metricMap['percent'] = 'TSP_REST_METRIC_PERCENT'

function plugin:onParseValues(data, extra)
    local success, parsed = parseJson(data)
    if not success then
        self:error('Can not parse metrics. Verify configuration parameters.')
        return
    end
    local measurements = {}
    local measurement = function (...)
        ipack(measurements, ...)
    end

    local results = parsed.results
    local timestamp = parsed.timestamp

    for i = 1, #results do
      measurement(metricMap[results[i].name], results[i].value, timestamp, results[i].name)
    end

    return measurements
end

plugin:run()

