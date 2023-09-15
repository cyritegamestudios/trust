local CyTest = require('cylibs/tests/cy_test')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local Event = require('cylibs/events/Luvent')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Color = require('cylibs/ui/views/color')
local View = require('cylibs/ui/views/view')
local Frame = require('cylibs/ui/views/frame')

local CollectionViewTests = {}
CollectionViewTests.__index = CollectionViewTests

function CollectionViewTests:onCompleted()
    return self.completed
end

function CollectionViewTests.new()
    local self = setmetatable({}, CollectionViewTests)
    self.completed = Event.newEvent()
    return self
end

function CollectionViewTests:destroy()
    self.completed:removeAllActions()
end

function CollectionViewTests:run()
    --self:testCollectionView()
    self:debug()
    --self:testViews()

    self:onCompleted():trigger(true)
end

-- Tests

function CollectionViewTests:testCollectionView()
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = CollectionViewCell.new(item)
        return cell
    end)

    local collectionView = CollectionView.new(dataSource, VerticalFlowLayout.new())

    collectionView:set_size(500, 500)
    collectionView:set_color(155, 0, 0, 0)
    collectionView:set_visible(true)
    collectionView:set_pos(500, 200)

    local item1 = TextItem.new('Item 1')
    dataSource:addItem(item1, IndexPath.new(1, 1))

    CyTest.assertEqual(function() return dataSource:numberOfSections()  end, 1, "numberOfSections()")
    CyTest.assertEqual(function() return dataSource:numberOfItemsInSection(1)  end, 1, "numberOfItemsInSection(1)")
    CyTest.assertEqual(function() return dataSource:itemAtIndexPath(IndexPath.new(1, 1))  end, item1, "itemAtIndexPath(1, 1)")

    local item2 = TextItem.new('Item 2')
    dataSource:addItem(item2, IndexPath.new(1, 2))

    CyTest.assertEqual(function() return dataSource:numberOfItemsInSection(1)  end, 2, "numberOfItemsInSection(1)")
    CyTest.assertEqual(function() return dataSource:itemAtIndexPath(IndexPath.new(1, 2))  end, item2, "itemAtIndexPath(1, 2)")

    dataSource:removeItem(IndexPath.new(1, 1))

    CyTest.assertEqual(function() return dataSource:itemAtIndexPath(IndexPath.new(1, 1))  end, item2, "itemAtIndexPath(1, 1)")
end

local PickerView = require('cylibs/ui/picker/picker_view')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local Mouse = require('cylibs/ui/input/mouse')
local texts = require('texts')

function CollectionViewTests:debug()
    local items = L{}
    for i = 1, 18 do
        items:append("Item "..i)
    end

    local pickerView = PickerView.withTextItems(items, Frame.new(500, 200, 200, 300))

    pickerView:setPosition(500, 200)
    pickerView:setSize(200, 300)
    pickerView:setVisible(true)

    pickerView:setNeedsLayout()
    pickerView:layoutIfNeeded()

    --[[local item = TextItem.new("Hello", TextStyle.Default.Button)

    local settings = item:getSettings()
    settings.pos.x = 500
    settings.pos.y = 600

    local textView = texts.new("${text}")

    textView.text = item:getText()
    textView:visible(true)
    textView:pos(500, 600)
    textView:draggable(true)

    local y_res = windower.get_windower_settings().ui_y_res
    for k, v in pairs(windower.get_windower_settings()) do
        print(k..', '..v)
    end

    Mouse.input():onMouseEvent():addAction(function(type, x, y, delta, blocked)
        print('hover: ('..x..', '..y..')')
        local pos_x, pos_y = textView:pos()
        print('text pos: ('..pos_x..', '..pos_y..')')
        if textView:hover(x, y) then
            print('hover yes '..y)
        else
            print('hover false '..y)
        end
        if type == 2 then
            textView:pos(x, y)
        end
        return false
    end)]]

    --test:setPosition(500, 500)
    --test:setSize(100, 20)

    --test:setNeedsLayout()
    --test:layoutIfNeeded()

    --print(pickerView.backgroundImageView.frame.width)
    --print(pickerView.backgroundImageView.frame.height)
    --print(pickerView.backgroundImageView.frame.x)
    --print(pickerView.backgroundImageView.frame.y)
    --print(tostring(pickerView.backgroundImageView:isVisible()))

    --[[local ListView = require('cylibs/ui/list_view/list_view')

    local items = L{}
    for i = 1, 18 do
        items:append("Item "..i)
    end

    local listView = ListView.verticalList(items, TextStyle.Default.Button, 20)

    listView:setScrollEnabled(true)
    listView:setScrollDelta(22) -- add itemSpacing
    listView:setPosition(500, 200)
    listView:setSize(300, 150)
    listView:setBackgroundColor(Color.new(175, 0, 0, 0))

    listView:setNeedsLayout()
    listView:layoutIfNeeded()]]

    --[[local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        return cell
    end)

    local collectionView = CollectionView.new(dataSource, VerticalFlowLayout.new(10))

    collectionView:setPosition(500, 200)
    collectionView:setSize(500, 500)
    collectionView:setBackgroundColor(Color.new(175, 0, 0, 0))

    collectionView:layoutIfNeeded()

    local item1 = TextItem.new('Item 1', TextStyle.Default.Text)
    dataSource:addItem(item1, IndexPath.new(1, 1))

    local item2 = TextItem.new('Item 2', TextStyle.Default.Text)
    dataSource:addItem(item2, IndexPath.new(1, 2))]]
end

function CollectionViewTests:testViews()
    local view1 = View.new(Frame.new(500, 200, 500, 500))
    view1:setBackgroundColor(Color.new(150, 0, 0 , 0))

    local view2 = View.new(Frame.new(500, 200, 100, 100))
    view2:setBackgroundColor(Color.new(150, 255, 0 , 0))

    view1:addSubview(view2)
    view1:setPosition(500, 200)
    view1:layoutIfNeeded()

    view2:setPosition(50, 50)
    view2:layoutIfNeeded()
end

return CollectionViewTests