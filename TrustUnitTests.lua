local ActionQueueTests = require('cylibs/tests/action_queue/action_queue_tests')
local CollectionViewTests = require('cylibs/tests/collection_view/collection_view_tests')

local runningTests = L{}

function handle_tests(test_name)
    if test_name == 'actions' then
        local test = ActionQueueTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    elseif test_name == 'cv' then
        local test = CollectionViewTests.new()

        test:onCompleted():addAction(function(success)
            print('Success is: '..tostring(success))
        end)

        runningTests:append(test)

        test:run()
    end
end