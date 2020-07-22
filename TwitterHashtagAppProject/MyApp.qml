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
                    placeholderText: "\uf099 e.g. tacotuesday"
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
            profile_name: "John Patric"
            text_description:  "Lorem ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            user_name: "@walter"
            image_url : "https://pbs.twimg.com/profile_images/1270771223081803778/uz7gEdxu_400x400.jpg"
            created_time : "2019"
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
            height: 150
            color: "transparent"
            Rectangle {
                id: banner
                color: "#EBF5FB"
                width: parent.width / 1.1;
                height: 150
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                radius: 7
                Column{
                    height: parent.height
                    width:parent.width
                    spacing: 3

                    //this Rectangle for the user ID stuff
                    Rectangle{
                        height: parent.height / 2.5
                        width: parent.width
                        color: "transparent"
                        id: userIDRectangle
                        Row{
                            id:userRowId
                            spacing: 10
                            width: parent.width
                            padding: 10
                            // anchors.left: profilePicture.right
                            Rectangle{
                                id: profilePicture
                                height: 60
                                width: 60
                                radius: 2
                                color: "transparent"

                                Image {
                                    id: profilePictureID
                                    source:image_url
                                    height: parent.height / 1.2
                                    width: parent.width / 1.2
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                            }//profile picture


                            Text {
                                font.family: fontAwesome.name
                                leftPadding: 6
                                text: profile_name
                                topPadding: 10
                                font.pixelSize: 10
                                font.bold: true
                                anchors.left : profilePicture.right
                                wrapMode: Text.WordWrap
                                id : titleID
                            }

                            Text {
                                font.family: fontAwesome.name
                                text:  getTweetIcon()+" " + user_name
                                font.pixelSize: 10
                                topPadding: 10
                                color: "#797D7F"
                                leftPadding: 15
                                anchors.left: titleID.right
                                id : nameID
                            }
                        }//row

                    }//User ID Rectangle

                    //this rectangle for the tweet

                    Rectangle{
                        width: parent.width

                        anchors.top : userIDRectangle.bottom
                        id:descriptionIDRectangle
                        Text {
                            width: parent.width / 1.6
                            text: text_description.substr(0, 150)
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            topPadding: 14
                            id : descriptionID
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }


                        Row{
                            topPadding: 10
                            spacing: 40
                            anchors.top: descriptionID.bottom
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            Button{
                                font.family: fontAwesome.name
                                text: "\uf064"

                                font.pixelSize: 15
                                flat: true
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: true
                                    onClicked : test();
                                }
                            }
                            Button{
                                font.family: fontAwesome.name
                                text: "\uf004"
                                font.pixelSize: 15
                                flat: true
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: true
                                    onClicked : test("Clicked " + titleID.text);
                                }
                            }
                        }


                    }//rectangle for the description and share and favorite icons

                }//column
            }//inner Rectangle

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
    }//Component (Delegation)

    /*
        This renders the list view of the tweets.
    */
    ScrollView {
        width: app.width
        height: parent.height / 2.5
        topPadding: 20
        anchors.top: mapView.bottom
        ListView {
            id:listViewID

            anchors.fill: parent.height / 2.5
            spacing: 12
            //  width: parent.width
            height: 200
            //   clip: true
            model: tweetModel
            delegate: tweetComponent

            Component.onCompleted: searchTweets("esri");
        }
    }






    /*
        This function will make a API request to the twitter
        and pull the information that has hashtag same as the users input.
    */
    function searchTweets(hashtag){

        //this adds the data to the list
        /*tweetModel.append({ "title" : "Corona" ,
                              "description" : "the cornavirus has hit most countries accros India.",
                              "hashtags" : "#corona" }); */



       // appTitleText.text = "hddddddddello World"
        //Making API request
        var xhr = new XMLHttpRequest();
        xhr.withCredentials = true;

        xhr.open("GET", "https://api.twitter.com/1.1/search/tweets.json?q=%23"+encodeURI(hashtag)+"&result_type=recent");

        //I removed this since uploading on github
        xhr.setRequestHeader("Authorization", //bearerID );


         xhr.onload = function (){
            var data = JSON.parse(xhr.responseText);

             //appTitleText.text = "Herte " + data.statuses[0].created_at;

             updateTweetCard(data.statuses);
        }
        xhr.send();

    }

    //this function will update the data to the ListElement

    function updateTweetCard(dataArray){
        if(dataArray.length === 0) return;

        tweetModel.clear();

        for(var i = 0; i < dataArray.length; i++){
            var currentTweet = dataArray[i];

            tweetModel.append({
                              "profile_name": currentTweet.user.name,
                               "text_description" : currentTweet.text,
                               "user_name" : currentTweet.user.screen_name,
                               "image_url" : currentTweet.user.profile_image_url_https,
                               "created_time" : currentTweet.created_at
                              });
        }

    }


    //this is helper function returns the tweet icon as a string
    function getTweetIcon(){
        return "\uf099";
    }

    //this is helper function returns the current date

    function test(data){

        appTitleText.text = data;
    }

    //this function returns the formatted date

    function getDate(dateData){

        var d = new Date(dateData);

        return "at " + d.toLocaleString() +".";
    }


}

