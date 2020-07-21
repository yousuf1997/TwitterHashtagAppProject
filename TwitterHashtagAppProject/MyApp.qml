/* Copyright 2020 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */


// You can run your app in Qt Creator by pressing Alt+Shift+R.
// Alternatively, you can run apps through UI using Tools > External > AppStudio > Run.
// AppStudio users frequently use the Ctrl+A and Ctrl+I commands to
// automatically indent the entirety of the .qml file.


import QtQuick 2.7
import QtQuick.Controls 2.13

import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.6
import QtGraphicalEffects 1.12


Rectangle {
    id: app
    width: 400
    height: 640
    property real scaleFactor: AppFramework.displayScaleFactor

    color: "#FBFCFC" //background color of the whole app

    //Matrial color for the app
    Material.accent: "#1DA1F2"

    //Load the Awesome font
    FontLoader {
        id: fontAwesome
        source: "assets/fontawesome-webfont.ttf"
    }




    /*The following component defines the header section of the app */
    Rectangle{
        id: headerBar
        width: parent.width
        height: 75
        color: "#1DA1F2"

        Text{
            id:appTitleText
            font.family: fontAwesome.name
            text: "\uf099 #HashtagLive"
            font.bold: true
            color:"White"
            font.pointSize: 25
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

        }

    }

    //this defines the search bar for tweet search
    Rectangle{
        width: parent.width
        anchors.top: headerBar.bottom
        height: 50 * scaleFactor
        color: "#AED6F1"
        id: searchBarParent
        Column {
            visible: portal.loadStatus === Enums.LoadStatusLoaded
            id: searchBox
            anchors {
                horizontalCenter: parent.horizontalCenter;
                verticalCenter: parent.verticalCenter
                margins: 10 * scaleFactor
            }
            spacing:2

            Row {
                spacing: 1
                TextField {
                    id: keyWordField
                    font.family: fontAwesome.name
                    placeholderText: "\uf099 e.g. #tacotuesday"
                    placeholderTextColor : "black"
                    width: 180 * scaleFactor
                    Keys.onReturnPressed: {
                        if (text.length > 0)
                            search(text);
                    }

                }

                Image {
                    source: "./assets/searchIcon.png"
                    width:  30 * scaleFactor
                    height: 30 * scaleFactor

                    // anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        enabled: keyWordField.text.length > 0
                        onClicked : searchTweets(keyWordField.text); //search function to load tweets
                    }
                }

                SequentialAnimation on x {
                    id: noResultsAnimation
                    loops: 10
                    running: false
                    PropertyAnimation { to: 50; duration: 20 }
                    PropertyAnimation { to: 0; duration: 20 }
                }

            }

        }//end of column
    }//rectangle



    //this is the map Component of the app
    MapView {
        id:mapView
        height: 250
        width: parent.width
        anchors.top: searchBarParent.bottom

        Map {
            id: map
            // Set the initial basemap to Topographic
            BasemapTopographic {}
            initialViewpoint: ViewpointCenter {
                center: Point {
                    x: -11e6
                    y: 6e6
                    spatialReference: SpatialReference {wkid: 102100}
                }
                targetScale: 9e7
            }
        }

    }





    /*
        List view model for the tweets
    */
    ListModel {
        id: tweetModel
        ListElement {
            title: "#HuricaneInFlorida"
            description:  "Lorem ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            hashtags: "#weather #florida"
        }
        ListElement {
            title: "#HuricaneInFlorida"
            description:  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            hashtags: "#weather #florida"
        }
        ListElement {
            title: "#HuricaneInFlorida"
            description:  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            hashtags: "#weather #florida"
        }
        ListElement {
            title: "#HuricaneInFlorida"
            description:  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            hashtags: "#weather #florida"
        }
        ListElement {
            title: "#HuricaneInFlorida"
            description:  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            hashtags: "#weather #florida"
        }



    }
    /*
        Delegation for the tweet list view.
     */
    Component {
        id: tweetComponent
        Rectangle {
            id: cardRectangle
            width: parent.width;
            height: 100
            color: "transparent"
            Rectangle {
                id: banner
                color: "#EBF5FB"
                width: parent.width / 1.20;
                height: 100
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                radius: 7


                Text {
                    font.family: fontAwesome.name
                    leftPadding: 6
                    text: title
                    font.pixelSize: 15
                    font.bold: true
                    width: parent.width
                    wrapMode: Text.WordWrap
                    id : titleID
                }

                Text {
                    font.family: fontAwesome.name
                    leftPadding: 8
                    text:  getTweetIcon()+ " By @jacdaniel"
                    font.pixelSize: 9
                    color: "#797D7F"
                    //font.bold: true
                    font.italic: true
                    width: parent.width
                    anchors.top: titleID.bottom
                    wrapMode: Text.WordWrap
                    id : nameID
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.top: nameID.bottom
                    leftPadding : 9
                    rightPadding: 20
                    text: description
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: 10
                    id : descriptionID
                }
                Text {
                    text: hashtags
                    id:hashTageId
                    leftPadding: 7
                    width: parent.width
                    font.bold: true
                    wrapMode: Text.WordWrap
                    font.italic: true
                    font.pixelSize:app.baseFontSize*0.5
                    anchors.top: descriptionID.bottom
                }
                Text {
                    text: "Posted at 07/21/2020 2:00AM"
                    color: "#797D7F"
                    anchors.top: hashTageId.bottom
                    leftPadding: 4
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize:app.baseFontSize*0.5

                }
            }//innner Rectangle

            //this renders the drop shawdow effects for the card
            DropShadow {
                anchors.fill: banner
                horizontalOffset: 3
                verticalOffset: 3
                radius: 8.0
                samples: 17
                color: "#80000000"
                source: banner
            }
        }//outter Rectangle
    }

    /*
        This renders the list view of the tweets.
    */
    ScrollView {
        width: app.width
        height: parent.height / 2.5
        topPadding: 20
        anchors.top: mapView.bottom
        ListView {
            anchors.fill: parent.height / 2.5
            spacing: 12
            //  width: parent.width
            height: 200
            //   clip: true
            model: tweetModel
            delegate: tweetComponent
        }
    }






    /*
        This function will make a API request to the twitter
        and pull the information that has hashtag same as the users input.
    */
    function searchTweets(hashtag){
        //appTitleText.text = hashtag;
    }

    //this is helper function returns the tweet icon as a string
    function getTweetIcon(){
        return "\uf099";
    }

    //this is helper function returns the current date


}

