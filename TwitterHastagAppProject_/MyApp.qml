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
import ArcGIS.AppFramework.Sql 1.0
import ArcGIS.AppFramework 1.0
import Esri.ArcGISRuntime 100.6

import QtGraphicalEffects 1.12
import ArcGIS.AppFramework.SecureStorage 1.0




App {
    id: app
    width: 480 * AppFramework.displayScaleFactor
    height: 650 * AppFramework.displayScaleFactor
    property int baseFontSize : app.info.propertyValue("baseFontSize", 16 * scaleFactor) + (isSmallScreen ? 0 : 3)
    property real scaleFactor: AppFramework.displayScaleFactor
    property var  graphicsOverlay : ArcGISRuntimeEnvironment.createObject("GraphicsOverlay");
    property var  locationArrayIndex : 0;
    property var listVisibity: true;
    property var coordinates: [];
    property bool changeOfWidth: false
    property bool changeOfHeight: false
    property bool newOrientation: false
    property bool verticalOrientation: true;



    //Material color for the app
    Material.accent: "#1DA1F2"

    //Load the Awesome font
    FontLoader {
        id: fontAwesome
        source: "assets/fontawesome-webfont.ttf"
    }

    FileFolder {
        id: fileFolder
        path: "~/ArcGIS/Data/Sql"
    }
    FileFolder {
        id: coordinatesScript
        path: "./Coordinates.js"
    }

    SqlDatabase {
        id: db
        databaseName: fileFolder.filePath("tweetDatabase.sqlite")
    }

    //when the root Rectangle component is completed
    Component.onCompleted: {
        fileFolder.makeFolder();
        db.open();

    }

    /*The following component defines the header section of the app */
    Rectangle{
        id: headerBar
        width: parent.width
        height: 10 * scaleFactor
        // height: scaleFactor * 10
        color: "#1DA1F2"

        Text{
            id:appTitleText
            font.family: fontAwesome.name
            text: "\uf099 #Live"
            //font.bold: true
            color:"White"
            font.pointSize: baseFontSize
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 10
            // anchors.horizontalCenter: parent.horizontalCenter

        }

    }
    //this defines the search bar for tweet search
    Rectangle{
        width: parent.width
        anchors.top: headerBar.bottom
        height: 40 * scaleFactor
        color: "#AED6F1"
        id: searchBarParent
        clip: true
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            leftPadding: 5
            spacing: 1
            TextField {
                id: keyWordField

                font.family: fontAwesome.name
                placeholderText: "e.g. tacotuesday"
                placeholderTextColor : "#ECF0F1"
                font.pointSize: baseFontSize
                height: searchBarParent * .50
                width: parent.width / 1.2

                Keys.onPressed: {

                }
                Keys.onReturnPressed: {

                    if (text.length > 0)
                        searchTweets(text);
                }

                Keys.onBackPressed: {

                }


            }

            RoundButton {

                width:  36 * scaleFactor
                height: 36 * scaleFactor
                font: fontAwesome.name
                text : "<p><font color='#ffffff'>"+getTweetIcon()+"</font></p>"

                highlighted: true
                // anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    enabled: keyWordField.text.length > 0
                    onClicked :  {
                        // resetHeader(true);
                        searchTweets(keyWordField.text);
                    } //search function to load tweets
                }
            }
        }



        //  }//end of inner Rectangle
    }//rectangle



    //this is the map Component of the app
    MapView {
        id:mapView
        height: 300 * scaleFactor
        //  height: parent.height * .40 * scaleFactor
        width: parent.width
        anchors.top: searchBarParent.bottom
        // anchors.bottom: scrollId.top
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
                Component.onCompleted: {
                    mapView.graphicsOverlays.append(graphicsOverlay);
                }
            }

        }



        onMouseClicked: {


            //  updateCallout(mouse.mapPoint.x, mouse.mapPoint.y);

        }

        //&#xf065;
        RoundButton {
            font.family: fontAwesome.name
            id:expandButtom
            anchors.top: parent.top
            anchors.right: parent.right
            text: "<font color='#ffffff'>\uf065</font>"
            font.pixelSize: 15
            height: 60 * scaleFactor
            width: 60 * scaleFactor
            highlighted: true
            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked : {

                    resizeMapview();
                    if(expandButtom.text === "<font color='#ffffff'>\uf065</font>"){
                        //expand the map
                        expandButtom.text = "<font color='#ffffff'>\uf00d</font>";
                    }else{
                        expandButtom.text = "<font color='#ffffff'>\uf065</font>";
                    }
                }
            }
        }

    }



    //Locator task geocoding
    LocatorTask {
        id: locatorTask
        url: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"


        onLoadStatusChanged: {
            if (loadStatus === Enums.LoadStatusLoaded) {
                console.log("Locator is ready to use");
            } else if (loadStatus === Enums.LoadStatusFailedToLoad) {
                console.log("Locator failed to load:", locatorTask.error.message);
            }
        }


        Component.onCompleted: {
            locatorTask.load();

        }
    }




    //List Model for Current Tweets and Favorites Tweets
    ListModel {
        id: tweetModel

        ListElement {
            profile_name: "John Patric"
            text_description:  "Lorem ipsum dolor sit amet,consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam"
            user_name: "@walter"
            image_url : "https://pbs.twimg.com/profile_images/1270771223081803778/uz7gEdxu_400x400.jpg"
            created_time : "2019" //this field will be used to hold the url of the tweet instead
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
            height: 145 * scaleFactor
            color: "transparent"


            Rectangle {
                id: banner
                // color: "#EBF5FB"
                color: "white"
                width:  333.4//parent.width / 1.2;
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                radius: 7
                Column{
                    height: parent.height
                    width:parent.width
                    // spacing: 1

                    //this Rectangle for the user ID stuff
                    Rectangle{
                        height: parent.height / 2.5
                        width: parent.width
                        color: "transparent"
                        id: userIDRectangle
                        Row{
                            id:userRowId
                            spacing: 3
                            width: parent.width
                            //   padding: 10
                            // anchors.left: profilePicture.right
                            Rectangle{
                                id: profilePicture
                                height: 60
                                width: 60
                                radius: 2
                                color: "transparent"

                                Image {
                                    id: profilePictureID
                                    source:image_url.replace("normal","400x400")
                                    height: parent.height / 1.5
                                    width: parent.width / 1.5
                                    //  visible: false
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                            }//profile picture */


                            Text {
                                font.family: fontAwesome.name
                                leftPadding: 6
                                text: profile_name.substr(0,25)
                                topPadding: 10
                                font.pixelSize: 10
                                font.bold: true
                                anchors.left : profilePicture.right
                                wrapMode: Text.WordWrap
                                id : titleID
                            }

                            Text {
                                font.family: fontAwesome.name
                                text:  getTweetIcon()+" @" + user_name.substr(0,20)
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
                            text: text_description.substr(0, 280)
                            wrapMode: Text.WordWrap
                            font.pixelSize: 10
                            maximumLineCount: 4
                            topPadding: 15
                            id : descriptionID
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Row{
                            topPadding: 2
                            spacing: 40
                            anchors.top: descriptionID.bottom
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            Button{
                                font.family: fontAwesome.name
                                text: "<font color='#1DA1F2'>\uf064 </font>"
                                font.pixelSize: 10
                                id : shareButton
                                width:  40 * scaleFactor
                                height: 40 * scaleFactor
                                flat: true
                                hoverEnabled: true
                                MouseArea {
                                    hoverEnabled: true
                                    anchors.fill: parent
                                    enabled: true
                                    onClicked : {
                                        shareButton.font.pixelSize = 15;
                                        AppFramework.clipboard.share(created_time);

                                        if(shareButton.text === "<font color='#1DA1F2'>\uf064 </font>"){

                                            //share logic should be placed here

                                            shareButton.text =  "<font color='#626567'> \uf064 </font>";
                                        }else{
                                            shareButton.text = "<font color='#1DA1F2'>\uf064 </font>";
                                        }
                                    }

                                    onExited: {
                                        shareButton.font.pixelSize = 10;

                                    }
                                }
                            }
                            Button{
                                font.family: fontAwesome.name
                                text: "<font color='#1DA1F2'> \uf004 </font>"
                                font.pixelSize: 10
                                id : favoriteButton
                                width:  40 * scaleFactor
                                height: 40 * scaleFactor
                                flat: true

                                //#E74C3C
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: true
                                    hoverEnabled: true
                                    //profileName, textDescription, userName, imageUrl, createdTime
                                    onClicked : {
                                        favoriteButton.font.pixelSize = 15;
                                        if(favoriteButton.text === "<font color='#1DA1F2'> \uf004 </font>"){
                                            insertRowToFT(profile_name,text_description,user_name,image_url,created_time);
                                            favoriteButton.text =  "<font color='#E74C3C'> \uf004 </font>";
                                        }else{
                                            favoriteButton.text = "<font color='#1DA1F2'> \uf004 </font>";
                                        }

                                    }
                                    onExited: {
                                        favoriteButton.font.pixelSize = 10;
                                    }
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


    ScrollView {
        topPadding: 3
        width: parent.width
        anchors.top: mapView.bottom
        //anchors.bottom: clearAndFavoriteLogo.top
        // height: parent.height * 0.35
        height: 250 * scaleFactor
        id : scrollId
        clip: true
        // anchors.top: clearAndFavoriteLogo.bottom


        ListView {
            id:listViewID
            spacing: 3
            height: parent.height
            model: tweetModel

            delegate: tweetComponent

            //some animation
            //it moves the data from position (100,100) to final destination
            add: Transition {
                NumberAnimation { properties: "y"; from : 200 ; duration: 500 }

            }


            Component.onCompleted: {
                populateRandomCoordinates();
                initTweetDatabase();
                initFavoriteTweetDatabase();

            }
        }
    }



    //This row consists the buttom for to go home, favorite, and clear the tweet database
    Row{
        id : clearAndFavoriteLogo
        height: 50 * scaleFactor
        //  width: parent.width
        anchors.top : scrollId.bottom
        anchors.right: parent.right
        anchors.rightMargin: 30 * scaleFactor
        anchors.bottomMargin: 35 * scaleFactor
        rightPadding: 10
        //  leftPadding: 10
        spacing: 3
        Button{
            font.family: fontAwesome.name

            width:  40 * scaleFactor
            height: 40 * scaleFactor
            text:"<font color='#fffff'>\uf015</font>"
            font.pixelSize: 10
            id: homeTweet
            highlighted: true
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: true
                onClicked :{
                    updateTwitterTable();

                }

            }

        }
        Button{
            font.family: fontAwesome.name
            anchors.top: mapView.bottom
            text: "<font color='#ffffff'>\uf004</font>"
            font.pixelSize: 10
            width:  40 * scaleFactor
            height: 40 * scaleFactor
            id: favoriteIcon
            highlighted: true
            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked : {
                    updateTweetFavoriteTable();
                }
            }
        }
        Button{
            font.family: fontAwesome.name
            anchors.top: mapView.bottom
            width:  40 * scaleFactor
            height: 40 * scaleFactor
            text:"<font color='#fffff'>\uf00d</font>"
            font.pixelSize: 10
            highlighted: true
            id: clearButton
            MouseArea {
                anchors.fill: parent
                enabled: true
                onClicked :{
                    //delete all databases
                    dropTable();
                    dropTableFavorite();
                    tweetModel.clear();
                    initTweetDatabase();
                    initFavoriteTweetDatabase();
                }

            }
        }

    }
    //Following detects the orientation of the screen

    onWidthChanged: {changeOfWidth = true; newOrientation = (changeOfWidth && changeOfHeight)}
    onHeightChanged: {changeOfHeight = true; newOrientation = (changeOfWidth && changeOfHeight)}

    onNewOrientationChanged: {
        if (newOrientation) {
            changeOfWidth = false;
            changeOfHeight = false;

            if (width > height) {
                // landscape
                verticalOrientation = false;
                landScapeMode();
            } else {
                // portrait
                verticalOrientation = true;
                portraitMode();
            }
        }
    }
    //end of orientation code

    //this function resets the header
    function resetHeader(onOroff){
        // height: parent.height * .02
        //if we want the header on
        if(onOroff){
            headerBar.visible = true;
            // headerBar.height = scaleFactor * 13;
            headerBar.height = app.height * 0.01;
            //searchBarParent.height = app.height * 0.08;
            searchBarParent.height = app.height * 0.06
        }else{
            headerBar.visible = false;
            headerBar.height = 0;
            //searchBarParent.height = app.height * 0.1;
            searchBarParent.height =  app.height * 0.07;
        }
    }


    //this function helps to geocode the address
    //Note: This function computes the cordinates based the on location string
    //if the location data has random value this might not work
    function geocodeTheAddress(locationArray, index){

        if(index >= locationArray.length) return;

        // set up signal handler for when the geocode completes
        locatorTask.geocodeStatusChanged.connect(function() {
            if (locatorTask.geocodeStatus === Enums.TaskStatusCompleted) {
                var results = locatorTask.geocodeResults;

                //for(var i = 0; i < results.length; i++)

                //insert the coordinates to the array
                coordinates.push({"x" : results[0].inputLocation.x , "y" : results[0].inputLocation.y});

                addTweetIconToMap(results[0].inputLocation.x,results[0].inputLocation.y);

            } else if (locatorTask.geocodeStatus === Enums.TaskStatusErrored) {

                //if it fails add random cordinates

                console.log("The locator task encountered an error:", locatorTask.error.message);
            }

            locationArrayIndex++;
            //recursive calls to compute the geo data for the rest of the locations
            geocodeTheAddress(locationArray, locationArrayIndex);

        });

        locatorTask.geocode(locationArray[index]);
    }


    //this function will add the icon to the Map
    function addTweetIconToMap(x,y){
        // create a graphic
        var point = ArcGISRuntimeEnvironment.createObject("Point", {x: x, y: y, spatialReference: SpatialReference.createWgs84()});
        var pictureMarkerSymbol = ArcGISRuntimeEnvironment.createObject(
                    "PictureMarkerSymbol", { url : "https://i.imgur.com/FyCUOGF.png",  width: 20.0
                        ,height: 20.0});
        var graphic = ArcGISRuntimeEnvironment.createObject("Graphic", {symbol: pictureMarkerSymbol, geometry: point});


        // add the graphic to the graphics overlay
        graphicsOverlay.graphics.append(graphic);

    }

    /*
        This function will make a API request to the twitter
        and pull the information that has hashtag same as the users input.
    */
    function searchTweets(hashtag){

        //stores the previous searched tweets
        SecureStorage.setValue("last_tweet", hashtag);

        //reset index 0, it will usefull to compute the geo location data for the locations
        locationArrayIndex = 0;

        //mapView.graphicsOverlays.

        //Making API request
        var xhr = new XMLHttpRequest();
        xhr.withCredentials = true;

        xhr.open("GET", "https://api.twitter.com/1.1/search/tweets.json?q=%23"+encodeURI(hashtag)+"&result_type=recent");

        //I removed this since uploading on github
        xhr.setRequestHeader("Authorization", "Bearer YOUR_CODE" );


        xhr.onload = function (){
            var data = JSON.parse(xhr.responseText);

            //           appTitleText.text = "Herte "

            //passing the statuses array to the function
            updateTweetCard(data.statuses);
        }
        xhr.send();

    }
    //this function will update the data to the ListElement
    function updateTweetCard(dataArray){
        if(dataArray.length === 0) return;

        tweetModel.clear();

        var locations = [];

        for(var i = 0; i < dataArray.length; i++){
            var currentTweet = dataArray[i];
            locations.push(currentTweet.user.location);
            var url_of_tweet = "https://twitter.com/"+currentTweet.user.id+"/status/"+currentTweet.id_str;
            tweetModel.append({
                                  "profile_name": currentTweet.user.name,
                                  "text_description" : currentTweet.text,
                                  "user_name" : currentTweet.user.screen_name,
                                  "image_url" : currentTweet.user.profile_image_url_https,
                                  "created_time" : url_of_tweet
                              });

            //inserts the data to the table
            insertRowToCT(currentTweet.user.name,  currentTweet.text  ,currentTweet.user.screen_name ,
                          currentTweet.user.profile_image_url_https ,url_of_tweet);
        }

        //passing the locations data to compute geocoding address
        geocodeTheAddress(locations, locationArrayIndex);

        // db.close();

    }


    //this is helper function returns the tweet icon as a string
    function getTweetIcon(){
        return "\uf099";
    }

    //this is helper function returns the current da
    //this function returns the formatted date

    function getDate(dateData){

        var d = new Date(dateData);

        return "at " + d.toLocaleString() +".";
    }


    //this function will help to resize the mapview, and change the visbility of the list
    function resizeMapview(){


        if(listVisibity){
            //since the list is visible
            //set it false
            listVisibity = false;
            listViewID.visible = false;
            clearAndFavoriteLogo.visible = false;

            //now expand the mapview to the rest of the screen
            if(!verticalOrientation){


                mapView.width = app.width;
                mapView.height = app.height
                //   verticalOrientation= false;
            } else{

                mapView.height = app.height;
            }
        }else{


            if(verticalOrientation){


                mapView.height = 300 * scaleFactor

            }else{

                landScapeMode();
            }

            listVisibity = true;
            listViewID.visible = true;
            clearAndFavoriteLogo.visible = true;
        }
    }

    //Database stuff --------------------------------------------------------------------------------------------

    function dropTable(){
        db.query("DROP TABLE IF EXISTS CURRENT_TWITTER_TABLE");
        SecureStorage.setValue("table_created", "no")
    }
    function dropTableFavorite(){
        db.query("DROP TABLE IF EXISTS FAVORITES_TWITTER_TABLE");
        SecureStorage.setValue("table_created_favorite", "no")
    }

    //this function will create table to store the current recent tweets
    //every time new tweets is being searched the old tweets in the database will be erased
    function initTweetDatabase(){

        //   db.open();

        if(!SecureStorage.value("table_created") || SecureStorage.value("table_created") === "no" ){

            //var delete_current_twitter_table = "DROP TABLE IF EXISTS CURRENT_TWITTER_TABLE";
            var create_current_twitter_table = "CREATE TABLE CURRENT_TWITTER_TABLE ( profile_name TEXT, text_description TEXT, user_name TEXT, image_url TEXT, created_time TEXT)";

            //  db.query("DROP TABLE IF EXISTS CURRENT_TWITTER_TABLE");
            db.query(create_current_twitter_table);

            searchTweets("Esri");
            SecureStorage.setValue("last_tweet", "Esri");

            keyWordField.placeholderText = "e.g Esri";

            SecureStorage.setValue("table_created", "created");
        }else{
            //set the search placeholder withe previous searched tweet
            keyWordField.placeholderText =  "e.g "+ SecureStorage.value("last_tweet");
            updateTwitterTable();
        }

    }
    //this function will create table to store the current recent tweets
    //every time new tweets is being searched the old tweets in the database will be erased
    function initFavoriteTweetDatabase(){

        // db.open();
        if(!SecureStorage.value("table_created_favorite") || SecureStorage.value("table_created_favorite") === "no" ){
            var create_favorite_twitter_table = "CREATE TABLE FAVORITES_TWITTER_TABLE (profile_name TEXT, text_description TEXT, user_name TEXT, image_url TEXT, created_time TEXT)";
            var result = db.query(create_favorite_twitter_table);

            SecureStorage.setValue("table_created_favorite", "yes");

        }


        // db.close();
    }


    //this function will populate tweet favorites to the list
    function updateTweetFavoriteTable(){

        //initTweetDatabase();
        var selectStatement = db.query("SELECT * FROM FAVORITES_TWITTER_TABLE;");
        var queryResult = selectStatement.first();
        //clear the listView
        tweetModel.clear();
        var currentTweets = [];
        //the following process will insert the values to the listViewID
        //we do not want the count to be more than 10
        var count = 0;

        while(queryResult){


            var json = JSON.stringify(selectStatement.values);

            var currentTweett = JSON.parse(json);
            currentTweets.push(currentTweett);

            //move to next Row
            queryResult = selectStatement.next();
        }

        //insert it to the list from end since the recent element is located
        //at the end

        var index = currentTweets.length - 1;

        while(index >= 0){
            var currentTweet = currentTweets[index];
            //insert into the list
            tweetModel.append({
                                  "profile_name": currentTweet.profile_name,
                                  "text_description" : currentTweet.text_description,
                                  "user_name" : currentTweet.user_name,
                                  "image_url" : currentTweet.image_url,
                                  "created_time" : currentTweet.created_time
                              });


            index--;
        }

        selectStatement.finish();
    }

    //this function inserts data to the current twitter database
    function insertRowToCT(profileName, textDescription, userName, imageUrl, createdTime){
        db.query("INSERT INTO CURRENT_TWITTER_TABLE VALUES ('" + profileName +"', '"+ textDescription + "', '"+userName +"', '" + imageUrl + "', '"+createdTime+"')");

    }

    //this function inserts data to the favroite twitter database
    function insertRowToFT(profileName, textDescription, userName, imageUrl, createdTime){
        db.query("INSERT INTO FAVORITES_TWITTER_TABLE VALUES ('" + profileName +"', '"+ textDescription + "', '"+userName +"', '" + imageUrl + "', '"+ createdTime+"')");
    }


    //this function will update the twitter table when the app opens
    function updateTwitterTable(){

        //  db.open();
        //initTweetDatabase();
        var selectStatement = db.query("SELECT * FROM CURRENT_TWITTER_TABLE;");

        var queryResult = selectStatement.first();
        //clear the listView
        tweetModel.clear();

        var currentTweets = [];

        //the following process will insert the values to the listViewID

        //we do not want the count to be more than 10
        var count = 0;

        while(queryResult){
            //  if(count === 10) break;


            var json = JSON.stringify(selectStatement.values);

            var currentTweett = JSON.parse(json);

            currentTweets.push(currentTweett);

            //move to next Row
            queryResult = selectStatement.next();
        }

        //insert it to the list from end since the recent element is located
        //at the end

        var index = currentTweets.length - 1;

        while(index >= 0){
            var currentTweet = currentTweets[index];
            //insert into the list
            tweetModel.append({
                                  "profile_name": currentTweet.profile_name,
                                  "text_description" : currentTweet.text_description,
                                  "user_name" : currentTweet.user_name,
                                  "image_url" : currentTweet.image_url,
                                  "created_time" : currentTweet.created_time
                              });
            index--;
        }



        selectStatement.finish();
        //   db.close();

    }

    //this function turns the phone into the landScapeMode()
    function landScapeMode(){

        //    expandButtom.visible = false;
        listVisibity = true;
        listViewID.visible = true;
        clearAndFavoriteLogo.visible = true;
        mapView.width = app.width / 2;
        mapView.anchors.left = app.left;
        expandButtom.text = "<font color='#ffffff'>\uf065</font>";
        scrollId.width = app.width / 2;
        scrollId.height = app.height / 1.6;
        scrollId.anchors.right = app.right;
        scrollId.anchors.top = searchBarParent.bottom;
        verticalOrientation= false;





    }
    //this function turns the phone into the portrait mode
    function portraitMode(){
        listVisibity = true;
        listViewID.visible = true;
        clearAndFavoriteLogo.visible = true;
        expandButtom.text = "<font color='#ffffff'>\uf065</font>";
        //  expandButtom.visible = true;
        mapView.width = app.width
        mapView.anchors.top = searchBarParent.bottom;
        mapView.height = 300 * scaleFactor;

        scrollId.width = app.width;
        scrollId.height = 250 * scaleFactor;
        scrollId.anchors.top = mapView.bottom;

        verticalOrientation= true;


    }

    //mock data for coordinates
    function populateRandomCoordinates(){



        coordinates.push({"x" : 34.558615, "y" : -120.079858});
        coordinates.push({"x" :  35.669206, "y" :  -120.972611});
        coordinates.push({"x" :   37.965971, "y" :-119.741600});
        coordinates.push({"x" :  33.103573, "y" : -115.370651});
        coordinates.push({"x" :   41.613361, "y" :-123.179714});
        coordinates.push({"x" :  39.482190, "y" :-119.837970});
        coordinates.push({"x" :  40.858355, "y" :-118.742031});
        coordinates.push({"x" :  39.469518, "y" :-118.651275});
        coordinates.push({"x" :   38.537453, "y" :-118.267545});
        coordinates.push({"x" :  41.584662, "y" :-119.473405});
        coordinates.push({"x" :   44.189696, "y" :-112.466608});
        coordinates.push({"x" :   31.430729, "y" :-100.391348});
        coordinates.push({"x" :   33.244137, "y" :-96.753470});
        coordinates.push({"x" :   34.332812, "y" :-95.085630});


        for(var i = 0; i < coordinates.length; i++){
            addTweetIconToMap(coordinates[i].y, coordinates[i].x);
        }

    }

    /*
    //this function will update the the callout information
    //including the Point,and data
    function updateCallout(x,y){

        searchTweets(SecureStorage.value("last_tweet"))

       var calloutDescription = tweetModel.get( Math.floor((Math.random() * tweetModel.count)));

        var p_name = calloutDescription.profile_name;
        var desc =  calloutDescription.text_description;
        var image_url = calloutDescription.image_url;
        var tweet_url = calloutDescription.created_time;

        tweetModel.clear();
        tweetModel.append(
                    {"profile_name" : p_name,
                     "text_description" : desc,
                     "image_url" : image_url,
                      "created_time" : tweet_url
                     });

    }

    //this calculates the shortest distance between two coordinates
    //this is the helper function to view the callout messages on the mapview
    function getMinDistancePoint(x, y){
        var minDistance = Number.MAX_SAFE_INTEGER;

        var returnPoint = {};

        for(var i = 0; i < coordinates.length; i++){
            var dis = calculateDistance({"x" : x, "y" : y},coordinates[i]);
            if(minDistance > dis){
                minDistance = dis;
                returnPoint = coordinates[i];
            }
        }

        return returnPoint;
    }

    //this function will calculate the distance between two coordinates
    function calculateDistance(point1, point2){

        var leftHandX = Math.pow((point2.x - point1.x), 2);
        var rightHandY = Math.pow((point2.y - point2.y), 2);

        return Math.sqrt(leftHandX, rightHandY);
    }
    */

}//end of the root Component

