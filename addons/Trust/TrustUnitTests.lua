require('cylibs/tests/run_tests')

local ActionQueueTests = require('cylibs/tests/action_queue/action_queue_tests')
local ListTests = require('cylibs/tests/list_tests')
local PartyTests = require('cylibs/tests/party/party_tests')
local TabbedViewTests = require('cylibs/tests/tabbed_view_tests')

local runningTests = L{}

function handle_tests(test_name)
    --run_unit_tests()
    if test_name == 'lists' then
        local test = ListTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    elseif test_name == 'tabs' then
        local test = TabbedViewTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    elseif test_name == 'actions' then
        local test = ActionQueueTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    elseif test_name == 'party' then
        local test = PartyTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    end
end