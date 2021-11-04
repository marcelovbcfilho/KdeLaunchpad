/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker

import "../code/tools.js" as Tools
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.4


Kicker.DashboardWindow {
    
    id: root

    property int iconSize:    plasmoid.configuration.iconSize
    property int spaceWidth:  plasmoid.configuration.spaceWidth
    property int spaceHeight: plasmoid.configuration.spaceHeight
    property int cellSizeWidth: spaceWidth + iconSize + theme.mSize(theme.defaultFont).height
                                + (2 * units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeHeight: spaceHeight + iconSize + theme.mSize(theme.defaultFont).height
                                 + (2 * units.smallSpacing)
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))


    property bool searching: (searchField.text != "")

    keyEventProxy: searchField
    backgroundColor: "transparent"

    property bool linkUseCustomSizeGrid: plasmoid.configuration.useCustomSizeGrid
    property int gridNumCols:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberColumns : Math.floor(width  * 0.85  / cellSizeWidth) // TODO: set from settings
    property int gridNumRows:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberRows : Math.floor(height * 0.8  /  cellSizeHeight)  // TODO: set from settings
    property int widthScreen:  gridNumCols * cellSizeWidth
    property int heightScreen: gridNumRows * cellSizeHeight
    property bool showFavorites: plasmoid.configuration.showFavorites
    property bool startIndex: (showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onKeyEscapePressed: {
        if (searching) {
            searchField.text = ""
        } else {
            root.toggle();
        }
    }

    onVisibleChanged: {
        reset();
        rootModel.pageSize = gridNumCols*gridNumRows
    }

    onSearchingChanged: {
        if (searching) {
            pageList.model = runnerModel;
            paginationBar.model = runnerModel;
        } else {
            reset();
        }
        
    }

    function reset() {
        if (!searching) {
            pageList.model = rootModel.modelForRow(0);
            paginationBar.model = rootModel.modelForRow(0);
        }
        searchField.text = "";
        pageListScrollArea.focus = true;
        pageList.currentIndex = startIndex;
        pageList.positionViewAtIndex(pageList.currentIndex, ListView.Contain);
        //pageList.currentItem.itemGrid.currentIndex = -1;
        //pageList.currentItem.itemGrid.tryActivate(0, 0);
    }

    mainItem: MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        focus: true
        hoverEnabled: true

        onClicked: {
            root.toggle();
        }

        Rectangle{
            anchors.fill: parent
            color: colorWithAlpha(theme.backgroundColor,0.6)
        }

        PlasmaExtras.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 5
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        ActionMenu {
            id: actionMenu
            onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
            onClosed: {
                if (pageList.currentItem) {
                    pageList.currentItem.itemGrid.currentIndex = -1;
                }
            }
        }

        PlasmaComponents.TextField {
            id: searchField

            anchors.top: parent.top
            anchors.topMargin: units.iconSizes.large
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.2
            style: TextFieldStyle {
                textColor: theme.textColor
                background: Rectangle {
                    radius: height*0.5
                    color: theme.textColor
                    opacity: 0.2
                }
            }
            placeholderText: "<font color='"+colorWithAlpha(theme.textColor,0.5) +"'>Plasma Search</font>"
            horizontalAlignment: TextInput.AlignHCenter
            focus: true
            onTextChanged: {
                runnerModel.query = text;
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Down) {
                    event.accepted = true;
                    pageList.currentItem.itemGrid.tryActivate(0, 0);
                } else if (event.key == Qt.Key_Right) {
                    if (cursorPosition == length) {
                        event.accepted = true;

                        if (pageList.currentItem.itemGrid.currentIndex == -1) {
                            pageList.currentItem.itemGrid.tryActivate(0, 0);
                        } else {
                            pageList.currentItem.itemGrid.tryActivate(0, 1);
                        }
                    }
                } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                    if (text != "" && pageList.currentItem.itemGrid.count > 0) {
                        event.accepted = true;
                        pageList.currentItem.itemGrid.tryActivate(0, 0);
                        pageList.currentItem.itemGrid.model.trigger(0, "", null);
                        root.toggle();
                    }
                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    //systemFavoritesGrid.tryActivate(0, 0);
                } else if (event.key == Qt.Key_Backtab) {
                    event.accepted = true;

                    if (!searching) {
                        pageList.currentIndex = 1;
                        filterList.forceActiveFocus();
                    } else {
                        //systemFavoritesGrid.tryActivate(0, 0);
                    }
                }
            }

            function backspace() {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text.slice(0, -1);

            }

            function appendText(newText) {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text + newText;
            }
        }

        PlasmaCore.IconItem {
            id: nepomunk
            source: "nepomuk"
            visible: true
            width:  searchField.height - 2
            height: width
            anchors {
                left: searchField.left
                leftMargin: 10
                verticalCenter: searchField.verticalCenter
            }

        }


        Rectangle{
            width:   widthScreen
            height:  heightScreen
            color: "transparent"
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            PlasmaExtras.ScrollArea {
                id: pageListScrollArea
                width: parent.width
                height: parent.height
                focus: true;
                frameVisible: false;
                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                ListView {
                    id: pageList
                    anchors.fill: parent
                    snapMode: ListView.SnapOneItem
                    highlightMoveDuration : plasmoid.configuration.scrollAnimationDuration
                    highlightMoveVelocity: -1
                    leftMargin: (showFavorites || searching) ? 0 : -widthScreen
                    orientation: Qt.Horizontal
                    onCurrentIndexChanged: {
                        //positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                    onCurrentItemChanged: {
                        if (!currentItem) {
                            return;
                        }
                        currentItem.itemGrid.focus = true;
                    }
                    onModelChanged: {
                        if(searching)
                            currentIndex = 0;
                        else{
                            currentIndex = startIndex;
                            positionViewAtIndex(currentIndex, ListView.Contain);
                        }
                    }
                    onMovingChanged: {
                        if (!moving) {
                            var pos = mapToItem(contentItem, width / 2, height / 2);
                            currentIndex = indexAt(pos.x, pos.y);
                            //currentItem.itemGrid.hoverEnabled = true;
                            //print("enabling for currentItem", currentItem.itemGrid.count);

                            // Disable hover for any itemGrids that we enabled while moving
                            //print("Looping for ", count);
                            // for(let x = (widthScreen / 2); x < count * widthScreen; x += widthScreen) {
                            //     var item = itemAt(x, heightScreen / 2);
                            //     if (item != null && item != currentItem) {
                            //         print("disabling for ", item.itemGrid.count);
                            //         item.itemGrid.hoverEnabled = false;
                            //     }
                            // }
                        }
                    }

                    function cycle() {
                        enabled = false;
                        enabled = true;
                    }

                    // Attempts to change index based on next. If next is true, increments,
                    // otherwise decrements. Stops on list boundaries. If activate is true, 
                    // also tries to activate what appears to be the next selected gridItem
                    function activateNextPrev(next, activate = true) {
                        // Carry over row data for smooth transition.
                        var lastRow = pageList.currentItem.itemGrid.currentRow();
                        if (activate)
                            pageList.currentItem.itemGrid.hoverEnabled = false;

                        var oldItem = pageList.currentItem;
                        if (next) {
                            var newIndex = pageList.currentIndex + 1;

                            if (newIndex < pageList.count) {
                                pageList.currentIndex = newIndex;
                            }
                        } else {
                            var newIndex = pageList.currentIndex - 1;

                            if (newIndex >= (showFavorites ? 0 : 1)) {
                                pageList.currentIndex = newIndex;
                            }
                        }

                        // Give old values to next grid if we changed
                        if(oldItem != pageList.currentItem) {
                            if (activate) {
                                pageList.currentItem.itemGrid.hoverEnabled = false;
                                pageList.currentItem.itemGrid.tryActivate(lastRow, next ? 0 : gridNumCols - 1);
                            } else if (oldItem) {
                                // TODO fix error where oldItem goes out of context?
                                oldItem.itemGrid.temporarilyEnableHover();
                            }
                        }
                    }

                    delegate: Item {

                        width:   gridNumCols * cellSizeWidth
                        height:  gridNumRows * cellSizeHeight

                        property Item itemGrid: gridView

                        visible: (showFavorites || searching) ? true : (index != 0)

                        ItemGridView {
                            id: gridView

                            property bool isCurrent: (pageList.currentIndex == index)
                            hoverEnabled: isCurrent

                            // Rectangle {
                            //     color: colorWithAlpha("red", 0.2)
                            //     anchors.fill: parent
                            //     visible: gridView.hoverEnabled
                            // }

                            visible: model.count > 0
                            anchors.fill: parent

                            cellWidth:  cellSizeWidth
                            cellHeight: cellSizeHeight

                            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                            dragEnabled: (index == 0) && plasmoid.configuration.showFavorites

                            model: searching ? runnerModel.modelForRow(index) : rootModel.modelForRow(0).modelForRow(index)
                            onCurrentIndexChanged: {
                                if (currentIndex != -1 && !searching) {
                                    pageListScrollArea.focus = true;
                                    focus = true;
                                }
                                //if(!visible && (currentIndex + 1) < pageList.count ){
                                //    currentIndex = currentIndex + 1
                                //}
                            }

                            onCountChanged: {
                                if (searching && index == 0) {
                                    currentIndex = 0;
                                }
                            }

                            onKeyNavUp: {
                                currentIndex = -1;
                                searchField.focus = true;
                            }

                            onKeyNavDown: {
                                if(plasmoid.configuration.showSystemActions) {
                                    currentIndex = -1;
                                    systemFavoritesGrid.focus = true;
                                    systemFavoritesGrid.tryActivate(0, 0);
                                }
                            }
                            onKeyNavRight: {
                                pageList.activateNextPrev(1);
                            }

                            onKeyNavLeft: {
                                pageList.activateNextPrev(0);
                            }
                        }

                        Kicker.WheelInterceptor {
                            anchors.fill: parent
                            z: 1

                            onWheelMoved: {
                                //event.accepted = false;
                                rootMouseArea.wheelDelta = rootMouseArea.scrollByWheel(rootMouseArea.wheelDelta, delta.y);
                            }
                        }
                    }
                }
            }

        }
        
        ItemGridView {
            id: systemFavoritesGrid

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: units.largeSpacing
                bottomMargin: units.smallSpacing
            }

            iconSize: plasmoid.configuration.systemActionIconSize
            visible: plasmoid.configuration.showSystemActions
            enabled: visible

            cellWidth: iconSize + units.largeSpacing
            cellHeight: cellWidth
            height: cellHeight
            width: cellWidth * count
            
            opacity: 0.9

            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            dragEnabled: true
            showLabels: false

            model: systemFavorites
            usesPlasmaTheme: true

            onCurrentIndexChanged: {
                focus = true;
            }

            onKeyNavLeft: {
                currentIndex = -1;
                pageList.currentItem.itemGrid.tryActivate(gridNumRows - 1, gridNumCols - 1);
            }

            onKeyNavUp: {
                currentIndex = -1;
                pageList.currentItem.itemGrid.tryActivate(gridNumRows - 1, gridNumCols - 1);
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    currentIndex = -1;
                    searchField.focus = true;
                } else if (event.key == Qt.Key_Backtab) {
                    event.accepted = true;
                    currentIndex = -1;
                    pageList.currentItem.itemGrid.tryActivate(0, 0);
                }
            }
        }

        ListView {
            id: paginationBar

            anchors {
                bottom: parent.bottom
                bottomMargin: units.largeSpacing
                horizontalCenter: parent.horizontalCenter
            }
            width: model.count * units.iconSizes.smallMedium
            height:  units.largeSpacing
            orientation: Qt.Horizontal

            delegate: Item {
                width: units.iconSizes.small
                height: width

                Rectangle {
                    id: pageDelegate
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                        margins: 10
                    }
                    width: parent.width  * 0.7
                    height: width

                    property bool isCurrent: (pageList.currentIndex == index)

                    radius: width / 2
                    color: theme.textColor
                    visible: (showFavorites || searching) ? true : (index != 0)
                    opacity: 0.5
                    Behavior on width { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }
                    Behavior on opacity { SmoothedAnimation { duration: units.longDuration; velocity: 0.01 } }

                    states: [
                        State {
                            when: pageDelegate.isCurrent
                            PropertyChanges { target: pageDelegate; width: parent.width - (units.smallSpacing * 1.75) }
                            PropertyChanges { target: pageDelegate; opacity: 1 }
                        }
                    ]
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pageList.currentIndex = index;
                }
            }
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                event.accepted = true;

                if (searching) {
                    reset();
                } else {
                    root.toggle();
                }

                return;
            }

            if (searchField.focus) {
                return;
            }

            if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                searchField.backspace();
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Backtab) {
                if (pageListScrollArea.focus == true && pageList.currentItem.itemGrid.currentIndex == -1) {
                    event.accepted = true;
                    pageList.currentItem.itemGrid.tryActivate(0, 0);
                }
            } else if (event.text != "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

        property int wheelDelta: 0

        function scrollByWheel(wheelDelta, eventDelta) {
            // magic number 120 for common "one click"
            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            wheelDelta += eventDelta;

            var increment = 0;

            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                increment++;
            }

            while (wheelDelta <= -120) {
                wheelDelta += 120;
                increment--;
            }

            while (increment != 0) {
                pageList.activateNextPrev(increment < 0, false);
                increment += (increment < 0) ? 1 : -1;
            }

            return wheelDelta;
        }

        onWheel: {
            wheelDelta = scrollByWheel(wheelDelta, wheel.angleDelta.y);
        }

        onPositionChanged: {
            var pos = mapToItem(pageList.contentItem, mouse.x, mouse.y);
            var hoveredPage = pageList.itemAt(pos.x, pos.y);
            if (!hoveredPage)
                return;
            var hoveredGrid = hoveredPage.itemGrid;
            
            // Note: onPositionChanged will not be triggered if the mouse is
            // currently over a gridView with hover enabled, so we know that
            // any hoveredGrid under the mouse at this point has hover disabled

            if (hoveredGrid != null) {
                //print("changed to", mouse.x, mouse.y);
                if (!pageList.moving) {
                    // If not flicking, only want current itemGrid
                    // (animation )
                    if (pageList.currentItem.itemGrid == hoveredGrid) {
                        hoveredGrid.hoverEnabled = true;
                        //print("Set");
                    }
                } else {
                    // If flicking, temporarily enable hover for all itemGrids
                    // for smoothness until currentIndex set in onMovingChanged
                    hoveredGrid.temporarilyEnableHover();
                }
            }
        }

    }

    Component.onCompleted: {
        rootModel.pageSize = gridNumCols*gridNumRows
        pageList.model = rootModel.modelForRow(0);
        paginationBar.model = rootModel.modelForRow(0);
        searchField.text = "";
        pageListScrollArea.focus = true;
        pageList.currentIndex = startIndex;
        kicker.reset.connect(reset);
    }
}
