//
// Copyright (C) 2013-2018 University of Amsterdam
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.
//


import QtQuick 2.11
import QtQuick.Controls 2.4 as QTCONTROLS
import QtQml.Models 2.2

import JASP.Widgets 1.0
import QtQuick.Layouts 1.3

JASPListControl
{
	id:						variablesList
	controlType:			"VariablesListView"
	height:					singleVariable ? jaspTheme.defaultSingleItemListHeight : jaspTheme.defaultVariablesFormHeight
	itemComponent:			itemVariableComponent

	property string itemType:			"variables"
	property alias	dropKeys:			dropArea.keys
	property string	dropMode:			"None"
	property bool	draggable:			true
	property var	sortMenuModel:		null
	property bool	showSortMenu:		true
	property bool	singleVariable:		false
	property string listViewType:		"AvailableVariables"
	property var	allowedColumns:		[]
	property bool	dropModeInsert:		dropMode === "Insert"
	property bool	dropModeReplace:	dropMode === "Replace"
	property var	selectedItemsTypes:	[]
	property var	suggestedColumns:	[]
	property bool	showElementBorder:	false
	property bool	dragOnlyVariables:	false
	property bool	showVariableTypeIcon:	true
	property bool	setWidthInForm:		false
	property bool	setHeightInForm:	false
	property bool	mustContainLowerTerms: true
	property bool	addAvailableVariablesToAssigned: listViewType === "Interaction"
	
	property var	interactionControl
	property bool	addInteractionOptions:	false

	property int	indexInDroppedListViewOfDraggedItem:	-1
	
	readonly property int rectangleY: listRectangle.y

	property int	startShiftSelected:	0
	property int	endShiftSelected:	-1
	property var	selectedItems:		[]
	property bool	mousePressed:		false
	property bool	shiftPressed:		false
	property var	draggingItems:		[]
	property var	itemContainingDrag
	
	signal itemDoubleClicked(int index);
	signal itemsDropped(var indexes, var dropList, int dropItemIndex, string assignOption);
	signal hasSelectedItemsChanged();
	signal draggingChanged(var context, bool dragging);

	function setSelectedItems()
	{
		var items = variablesList.getExistingItems()
		variablesList.selectedItemsTypes = []
		for (var i = 0; i < items.length; i++)
		{
			var item = items[i]
			if (variablesList.selectedItems.includes(item.rank))
			{
				item.selected = true
				if (!variablesList.selectedItemsTypes.includes(item.columnType))
					variablesList.selectedItemsTypes.push(item.columnType)
			}
			else
				item.selected = false;
		}

		hasSelectedItemsChanged();
	}

	function setEnabledState(source, dragging)
	{
		var result = !dragging;
		if (dragging)
		{
			if (source.selectedItems.length > 0)
			{
				if (variablesList.allowedColumns.length > 0)
				{
					result = true;
					for (var i = 0; i < source.selectedItemsTypes.length; i++)
					{
						var itemType = source.selectedItemsTypes[i];
						if (!variablesList.allowedColumns.includes(itemType))
							result = false;
					}
				}
				else
					result = true;
			}
		}

		// Do not use variablesList.enabled: this may break the binding if the developer used it in his QML form.
		listRectangle.enabled = result
		listTitle.enabled = result
	}


	function moveSelectedItems(target)
	{
		if (variablesList.selectedItems.length === 0) return;

		var assignOption = (target && target.interactionControl) ? target.interactionControl.model.get(target.interactionControl.currentIndex).value : ""
		itemsDropped(selectedItems, target, -1, assignOption);
		variablesList.clearSelectedItems(true);
	}



	function getExistingItems()
	{
		var items = [];
		for (var i = 0; i < listGridView.contentItem.children.length; i++)
		{
			var item = listGridView.contentItem.children[i];
			if (item.children.length === 0)
				continue;
			item = item.children[0];
			if (item.objectName === "itemRectangle")
				items.push(item);
		}

		return items;
	}

	function addSelectedItem(itemRank)
	{
		if (selectedItems.includes(itemRank))
			return;

		selectedItems.push(itemRank);
		selectedItems.sort();
		variablesList.setSelectedItems()
	}

	function removeSelectedItem(itemRank)
	{
		var index = selectedItems.indexOf(itemRank)
		if (index >= 0)
		{
			selectedItems.splice(index, 1);
			variablesList.setSelectedItems()
		}
	}

	function clearSelectedItems(emitSignal)
	{
		selectedItems = [];
		if (emitSignal)
			variablesList.setSelectedItems()
	}

	function selectShiftItems(selected)
	{
		var startIndex = variablesList.startShiftSelected;
		var endIndex = variablesList.endShiftSelected;
		if (startIndex > endIndex)
		{
			var temp = startIndex;
			startIndex = endIndex;
			endIndex = temp;
		}

		if (selected)
		{
			for (var i = startIndex; i <= endIndex; i++)
			{
				if (!variablesList.selectedItems.includes(i))
					variablesList.selectedItems.push(i)
			}
			variablesList.selectedItems.sort();
		}
		else
		{
			for (var i = startIndex; i <= endIndex; i++)
			{
				var index = selectedItems.indexOf(i)
				if (index >= 0)
					selectedItems.splice(index, 1);
			}
		}
		variablesList.setSelectedItems()
	}

		
	Repeater
	{
		model: suggestedColumns

		Image
		{
			source: jaspTheme.iconPath + (enabled ? iconInactiveFiles[suggestedColumns[index]] : iconDisabledFiles[suggestedColumns[index]])
			height: 16 * preferencesModel.uiScale
			width:	16 * preferencesModel.uiScale
			z:		2
			anchors
			{
				bottom:			listRectangle.bottom;
				bottomMargin:	4  * preferencesModel.uiScale
				right:			listRectangle.right;
				rightMargin:	(index * 20 + 4)  * preferencesModel.uiScale + (scrollBar.visible ? scrollBar.width : 0)
			}
		}
	}

	DropArea
	{
		id:				dropArea
		anchors.fill:	listRectangle

		onPositionChanged:
		{
			if (variablesList.singleVariable || (!variablesList.dropModeInsert && !variablesList.dropModeReplace)) return;

			var onTop = true;
			var item = listGridView.itemAt(drag.x, drag.y + listGridView.contentY)
			if (item && item.children.length > 0)
				item = item.children[0];
			if (!item || item.objectName !== "itemRectangle")
			{
				if (listGridView.count > 0)
				{
					var items = variablesList.getExistingItems();
					if (items.length > 0)
					{
						var lastItem = items[items.length - 1];
						if (lastItem.rank === (listGridView.count - 1) && drag.y > (lastItem.height * listGridView.count))
						{
							item = lastItem
							onTop = false;
						}
					}
				}
			}
			if (item && item.objectName === "itemRectangle")
			{
				dropLine.parent = item
				dropLine.visible = true
				dropLine.onTop = onTop
				variablesList.itemContainingDrag = item
				variablesList.indexInDroppedListViewOfDraggedItem = onTop ? item.rank : -1
			}
			else
			{
				dropLine.visible = false
				variablesList.itemContainingDrag = null
				variablesList.indexInDroppedListViewOfDraggedItem = -1
			}
		}
		onExited:
		{
			dropLine.visible = false
			variablesList.itemContainingDrag = null
			variablesList.indexInDroppedListViewOfDraggedItem = -1
		}
	}
		
	Component.onCompleted:
	{
		var mySuggestedColumns = []
		var myAllowedColumns = []

		if (typeof suggestedColumns === "string")
			mySuggestedColumns.push(suggestedColumns)
		else
			mySuggestedColumns = suggestedColumns.concat()
		if (typeof allowedColumns === "string")
			myAllowedColumns.push(allowedColumns)
		else
			myAllowedColumns = allowedColumns.concat()

		if (mySuggestedColumns.length === 0 && myAllowedColumns.length > 0)
			mySuggestedColumns = myAllowedColumns.concat()
		else if (myAllowedColumns.length === 0 && mySuggestedColumns.length > 0)
		{
			myAllowedColumns = mySuggestedColumns.concat()
			if (mySuggestedColumns.includes("scale"))
			{
				if (!myAllowedColumns.includes("nominal"))
					myAllowedColumns.push("nominal")
				if (!myAllowedColumns.includes("ordinal"))
					myAllowedColumns.push("ordinal")
			}
			if (mySuggestedColumns.includes("nominal"))
			{
				if (!myAllowedColumns.includes("nominalText"))
					myAllowedColumns.push("nominalText")
				if (!myAllowedColumns.includes("ordinal"))
					myAllowedColumns.push("ordinal")
			}
		}
		suggestedColumns = mySuggestedColumns.concat()
		allowedColumns = myAllowedColumns.concat()
	}
			

	Rectangle
	{
		id:				dropLine
		height:			1
		width:			parent ? parent.width : 0
		anchors.top:	parent ? (onTop ? parent.top : parent.bottom) : undefined
		anchors.left:	parent ? parent.left : undefined
		color:			jaspTheme.blueLighter
		visible:		false

		property bool onTop: true
	}

	SortMenuButton
	{
		visible: variablesList.showSortMenu && variablesList.sortMenuModel && listGridView.count > 1
		anchors
		{
			top:			listRectangle.top
			right:			listRectangle.right
			rightMargin:	5 * preferencesModel.uiScale + (scrollBar.visible ? scrollBar.width : 0)
			topMargin:		5 * preferencesModel.uiScale
		}

		sortMenuModel: variablesList.sortMenuModel
		scrollYPosition: backgroundForms.contentY
	}
			
	listGridView.onCurrentItemChanged:
	{
		if (variablesList.shiftPressed)
		{
			if (variablesList.endShiftSelected >= 0)
				selectShiftItems(false);
			variablesList.endShiftSelected = listGridView.currentIndex;
			selectShiftItems(true);
		}
		else if (!mousePressed)
		{
			var itemWrapper = listGridView.currentItem;
			if (itemWrapper)
			{
				var itemRectangle = itemWrapper.children[0];
				variablesList.clearSelectedItems(false);
				variablesList.addSelectedItem(itemRectangle.rank);
				variablesList.startShiftSelected = listGridView.currentIndex;
				variablesList.endShiftSelected = -1;
			}
		}
	}
			
	Keys.onPressed:
	{
		if (event.key === Qt.Key_Shift)
			variablesList.shiftPressed = true;
	}

	Keys.onReleased:
	{
		if (event.key === Qt.Key_Shift)
			variablesList.shiftPressed = false;
	}

	Keys.onSpacePressed:
	{
		moveSelectedItems()
	}
	Keys.onReturnPressed:
	{
		moveSelectedItems()
	}
	
	Component
	{
		id: itemVariableComponent

		FocusScope
		{
			id:			itemWrapper
			height:		listGridView.cellHeight
			width:		listGridView.cellWidth
			
			Component.onDestruction:
			{
				if (itemRectangle.extraColumnsModel)
					itemRectangle.extraColumnsModel.controlsDestroyed()
			}

			Rectangle
			{
				id:							itemRectangle
				objectName:					"itemRectangle"
				anchors.horizontalCenter:	parent.horizontalCenter
				anchors.verticalCenter:		parent.verticalCenter
				// the height & width of itemWrapper & itemRectangle must be set independently of each other:
				// when the rectangle is dragged, it gets another parent but it must keep the same size,
				height:			listGridView.cellHeight
				width:			listGridView.cellWidth
				focus:			true
				border.width:	containsDragItem && variablesList.dropModeReplace ? 2 : (variablesList.showElementBorder ? 1 : 0)
				border.color:	containsDragItem && variablesList.dropModeReplace ? jaspTheme.containsDragBorderColor : jaspTheme.grayLighter
				
				
				property bool clearOtherSelectedItemsWhenClicked: false
				property bool selected:				variablesList.selectedItems.includes(rank)
				property bool isDependency:			variablesList.dependencyMustContain.indexOf(colName.text) >= 0
				property bool dragging:				false
				property int offsetX:				0
				property int offsetY:				0
				property int rank:					index
				property bool containsDragItem:		variablesList.itemContainingDrag === itemRectangle
				property bool isVirtual:			(typeof model.type !== "undefined") && model.type.includes("virtual")
				property bool isVariable:			(typeof model.type !== "undefined") && model.type.includes("variable")
				property bool isLayer:				(typeof model.type !== "undefined") && model.type.includes("layer")
				property bool draggable:			variablesList.draggable && (!variablesList.dragOnlyVariables || isVariable)
				property string columnType:			isVariable && (typeof model.columnType !== "undefined") ? model.columnType : ""
				property var extraColumnsModel:		model.extraColumns

				enabled: variablesList.listViewType != "AvailableVariables" || !columnType || variablesList.allowedColumns.length == 0 || (variablesList.allowedColumns.indexOf(columnType) >= 0)
				
				function setRelative(draggedRect)
				{
					x = Qt.binding(function (){ return draggedRect.x + offsetX; })
					y = Qt.binding(function (){ return draggedRect.y + offsetY; })
				}
				
				color:
				{
					if(itemRectangle.isDependency)											return itemRectangle.selected ? jaspTheme.dependencySelectedColor : jaspTheme.dependencyBorderColor;
					if (!itemRectangle.draggable)											return jaspTheme.controlBackgroundColor;
					if (itemRectangle.selected)												return variablesList.activeFocus ? jaspTheme.itemSelectedColor: jaspTheme.itemSelectedNoFocusColor;
					if (itemRectangle.containsDragItem && variablesList.dropModeReplace)	return jaspTheme.itemSelectedColor;
					if (mouseArea.containsMouse)											return jaspTheme.itemHoverColor;

					return jaspTheme.controlBackgroundColor;
				}

				Drag.keys:		[variablesList.name]
				Drag.active:	mouseArea.drag.active
				Drag.hotSpot.x:	itemRectangle.width / 2
				Drag.hotSpot.y:	itemRectangle.height / 2
				
				// Use the ToolTip Attached property to avoid creating ToolTip object for each item
				QTCONTROLS.ToolTip.visible: mouseArea.containsMouse && model.name && !itemRectangle.containsDragItem && colName.truncated
				QTCONTROLS.ToolTip.delay: 300
				QTCONTROLS.ToolTip.text: model.name
				
				Image
				{
					id:						icon
					height:					15 * preferencesModel.uiScale
					width:					15 * preferencesModel.uiScale
					anchors.verticalCenter:	parent.verticalCenter
					source:					(!(variablesList.showVariableTypeIcon && itemRectangle.isVariable) || !model.columnType) ? "" : jaspTheme.iconPath + (enabled ? iconFiles[model.columnType] : iconDisabledFiles[model.columnType])
					visible:				variablesList.showVariableTypeIcon && itemRectangle.isVariable
				}
				Text
				{
					id:						colName
					x:						(variablesList.showVariableTypeIcon ? 20 : 4) * preferencesModel.uiScale
					text:					model.name
					width:					itemRectangle.width - x - extraControls.width
					elide:					Text.ElideRight
					anchors.verticalCenter:	parent.verticalCenter
					horizontalAlignment:	itemRectangle.isLayer ? Text.AlignHCenter : undefined
					color:					!enabled ? jaspTheme.textDisabled : itemRectangle.isVirtual ? jaspTheme.grayLighter : (itemRectangle.color === jaspTheme.itemSelectedColor ? jaspTheme.white : jaspTheme.black)
					font:					jaspTheme.font
				}
				
				ExtraControls
				{
					id:					extraControls
					model:				itemRectangle.extraColumnsModel
					controlComponents:  variablesList.extraControlComponents
				}
				
				states: [
					State
					{
						when: itemRectangle.dragging
						ParentChange
						{
							target: itemRectangle
							parent: form
						}
						AnchorChanges
						{
							target: itemRectangle
							anchors.horizontalCenter: undefined
							anchors.verticalCenter: undefined
						}
						PropertyChanges
						{
							target: itemRectangle
							opacity: 0.4
						}
					}
				]
				
				MouseArea
				{
					id:				mouseArea
					anchors.fill:	parent
					drag.target:	itemRectangle.draggable ? parent : null
					hoverEnabled:	true
					cursorShape:	Qt.PointingHandCursor
					
					onDoubleClicked:
					{
						if (itemRectangle.draggable)
						{
							variablesList.clearSelectedItems(true); // Must be before itemDoubleClicked: listView does not exist anymore afterwards
							itemDoubleClicked(index);
						}
					}
					
					onClicked:
					{
						if (itemRectangle.clearOtherSelectedItemsWhenClicked)
						{
							variablesList.clearSelectedItems(false)
							variablesList.addSelectedItem(itemRectangle.rank)
						}
					}
					
					onPressed:
					{
						variablesList.mousePressed = true
						listGridView.currentIndex = index;
						itemRectangle.clearOtherSelectedItemsWhenClicked = false
						if (mouse.modifiers & Qt.ControlModifier)
						{
							if (itemRectangle.selected)
								variablesList.removeSelectedItem(itemRectangle.rank)
							else
								variablesList.addSelectedItem(itemRectangle.rank)
							variablesList.startShiftSelected = index
							variablesList.endShiftSelected = -1
						}
						else if (mouse.modifiers & Qt.ShiftModifier)
						{
							if (variablesList.endShiftSelected >= 0)
								variablesList.selectShiftItems(false)
							variablesList.endShiftSelected = index
							variablesList.selectShiftItems(true)
						}
						else
						{
							itemWrapper.forceActiveFocus()
							if (!itemRectangle.selected)
							{
								variablesList.clearSelectedItems(false);
								variablesList.addSelectedItem(itemRectangle.rank);
							}
							else
							{
								itemRectangle.clearOtherSelectedItemsWhenClicked = true;
							}
							
							variablesList.startShiftSelected = index;
							variablesList.endShiftSelected = -1;
						}
					}
					onReleased:
					{
						variablesList.mousePressed = false;
					}
					
					drag.onActiveChanged:
					{
						variablesList.draggingChanged(variablesList, drag.active)
						if (drag.active)
						{
							if (itemRectangle.selected)
							{
								variablesList.draggingItems = []
								variablesList.draggingItems.push(itemRectangle)
								itemRectangle.dragging = true;

								var items = variablesList.getExistingItems();
								for (var i = 0; i < items.length; i++)
								{
									var item = items[i];
									if (!variablesList.selectedItems.includes(item.rank))
										continue;

									if (item.rank !== index)
									{
										variablesList.draggingItems.push(item)
										item.dragging = true;
										item.offsetX = item.x - itemRectangle.x;
										item.offsetY = item.y - itemRectangle.y;
										item.setRelative(itemRectangle);
									}
								}
							}
							
						}
						else
						{
							for (var i = 0; i < variablesList.draggingItems.length; i++)
							{
								var draggingItem = variablesList.draggingItems[i];
								if (!draggingItem.dragging)
									continue;

								draggingItem.dragging = false;
								draggingItem.x = draggingItem.x; // break bindings
								draggingItem.y = draggingItem.y;
							}
							if (itemRectangle.Drag.target)
							{
								var dropTarget = itemRectangle.Drag.target.parent
								if (dropTarget.singleVariable && variablesList.selectedItems.length > 1)
									return;
								
								var variablesListName = variablesList.name
								var assignOption = dropTarget.interactionControl ? dropTarget.interactionControl.model.get(dropTarget.interactionControl.currentIndex).value : ""
								itemsDropped(variablesList.selectedItems, dropTarget, dropTarget.indexInDroppedListViewOfDraggedItem, assignOption);
								variablesList.clearSelectedItems(true);
							}
						}
					}
				}
			}
		}
	}

}
