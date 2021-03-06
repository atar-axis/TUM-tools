// ==UserScript==
// @author   Florian Dollinger
// @name        mediasite tum downloader
// @namespace   wireless
// @include     http://streams.tum.de/Mediasite/*
// @include     https://streams.tum.de/Mediasite/*
// @version     1
// @require   https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js
// @require  https://gist.github.com/raw/2625891/waitForKeyElements.js
// @grant    GM_addStyle
// ==/UserScript==

// Visit the Mediasite Website via the HTTP (not the HTTPS) link!
// Modifiy the following string to fit your needs:
ref = location.protocol+'//streams.tum.de/Mediasite/Catalog/catalogs/analysis-2016';

function addGlobalStyle(css) {
    var head, style;
    head = document.getElementsByTagName('head')[0];
    if (!head) { return; }
    style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = css;
    head.appendChild(style);
}

// Platziert den Download-Button neben den Info und Watch Buttons
function placeButton(panel, vid_location, title){

    var dwnlink = document.createElement('a');
    dwnlink.id = 'Download';
    dwnlink.className = 'navLinkDivider';
    dwnlink.href = vid_location;

    dwnlink.title = panel.querySelector('#cardTitle').firstChild.data.match(/\w+/g).join('_');


    dwnlink.appendChild(document.createTextNode(title));

    panel.querySelector('#navPanel').appendChild(dwnlink);

}

// Sendet die HTTP Anfrage an den Mediasite-Server und wertet die Antwort aus,
// in welcher sich der Speicherort der Mediendateien befindet
function modify (i) {

    var panels = document.getElementsByClassName("tdPresentationDetails");
    var href, strip, rsrcID, catID, referrer, params, http, url;

    // alle videos durchlaufen
    if (i < panels.length) {

        // mediasite-videolink auslesen
        href = panels[i].querySelector('#Launch').href;
        //alert(href);

        // video details für die link-abfrage vorbereiten
        strip = href.match(/(?:Play\/)(.*)(?:\?)(?:catalog=)(.*)(?:\?)?/);
        rsrcID = strip[1];
        catID = strip[2];
        referrer = ref;

        // combine
        params = '{"getPlayerOptionsRequest":{"ResourceId":"'+rsrcID+'","QueryString":"?catalog='+catID+'","UseScreenReader":false,"UrlReferrer":"'+referrer+'"}}';
        //alert(params);

        // prepare request
        http = new XMLHttpRequest();
        url = location.protocol+"//streams.tum.de/Mediasite/PlayerService/PlayerService.svc/json/GetPlayerOptions";
        vid_location = [];

        http.open("POST", url, true);
        http.setRequestHeader("Content-type", "application/json");

        http.onreadystatechange = function() {

            if(http.readyState == 4 && http.status == 200) {


                var response = jQuery.parseJSON(http.responseText);
                //console.log(http.responseText);

                // Durchsuche alle Streams nach dem MP4-Link

                var len_streams_array = response.d.Presentation.Streams.length;

                for(var k = 0; k < len_streams_array; k++){

                    var len_urls_array = response.d.Presentation.Streams[k].VideoUrls.length;

                    for(var j = 0; j < len_urls_array; j++){

                        if(response.d.Presentation.Streams[k].VideoUrls[j].MediaType == "MP4"){

                            vid_location.push(response.d.Presentation.Streams[k].VideoUrls[j].Location);
                            //alert("DBG: Im Stream "+k+" wurde ein MP4-Link gefunden!");
                            //console.log(vid_location.pop());
                            //break;

                        }
                    }


                    // TODO: Slides

                    if (response.d.Presentation.Streams[k].Slides.length != 0) {

                        var base_url = response.d.Presentation.Streams[k].SlideBaseUrl;
                        var img_template = response.d.Presentation.Streams[k].SlideImageFileNameTemplate;
                        var ticketId = response.d.Presentation.Streams[k].SlidePlaybackTicketId;


                        for(var l = 0; l < response.d.Presentation.Streams[k].Slides.length; l++){

                            var img_no = ("0000" + response.d.Presentation.Streams[k].Slides[l].Number).slice (-4);
                            var img_name = img_template.replace('{0:D4}', img_no);

                            console.log(base_url+img_name+"?playbackTicket="+ticketId);

                        }

                    }

                    //break;
                }



                for(var l = 0; l < vid_location.length; l++){
                    placeButton(panels[i], vid_location[l], "Download "+l);
                }

                // Rufe diese Funktion erneut für den nächsten Eintrag auf.
                modify(++i);

            }
        };

        http.send(params);

    } else {

        alert("Links ready");
        document.querySelector('#SearchResults').setAttribute('data-wasActive', 1);

    }

}

// Erzeugt den Button zur Erzeugung der Downloadlinks
// Nicht automatisiert, da die Abfrage bisher viel Zeit benötigt und nur
// dann ausgeführt werden soll, wenn nötig
function create_downloads(){

    var dwn_creator = document.createElement('a');
    dwn_creator.id = 'Create_Downloads';
    dwn_creator.className = 'myButton';
    dwn_creator.onclick = function(){

        if(document.querySelector('#SearchResults').getAttribute('data-wasActive') === null){
            //alert("call modify");
            modify(0);
        } else {
            alert("nothing to do...");
        }


    };
    dwn_creator.title = 'Create Download';
    dwn_creator.appendChild(document.createTextNode('Create Downloadlinks'));

    document.querySelector('#PageHeader').appendChild(dwn_creator);

    addGlobalStyle("a.myButton{ -moz-box-shadow:inset 0px 1px 0px 0px #54a3f7; -webkit-box-shadow:inset 0px 1px 0px 0px #54a3f7; box-shadow:inset 0px 1px 0px 0px #54a3f7; background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #007dc1), color-stop(1, #0061a7)); background:-moz-linear-gradient(top, #007dc1 5%, #0061a7 100%); background:-webkit-linear-gradient(top, #007dc1 5%, #0061a7 100%); background:-o-linear-gradient(top, #007dc1 5%, #0061a7 100%); background:-ms-linear-gradient(top, #007dc1 5%, #0061a7 100%); background:linear-gradient(to bottom, #007dc1 5%, #0061a7 100%); filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#007dc1', endColorstr='#0061a7',GradientType=0); background-color:#007dc1; -moz-border-radius:3px; -webkit-border-radius:3px; border-radius:3px; border:1px solid #124d77; display:inline-block; cursor:pointer; color:#ffffff; font-family:arial; font-size:13px; margin: 10px 0px 5px 10px; padding:6px 24px; text-decoration:none; text-shadow:0px 1px 0px #154682; } .myButton:hover { background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #0061a7), color-stop(1, #007dc1)); background:-moz-linear-gradient(top, #0061a7 5%, #007dc1 100%); background:-webkit-linear-gradient(top, #0061a7 5%, #007dc1 100%); background:-o-linear-gradient(top, #0061a7 5%, #007dc1 100%); background:-ms-linear-gradient(top, #0061a7 5%, #007dc1 100%); background:linear-gradient(to bottom, #0061a7 5%, #007dc1 100%); filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#0061a7', endColorstr='#007dc1',GradientType=0); background-color:#0061a7; } .myButton:active { position:relative; top:1px; }");



}

waitForKeyElements (".cardDataListStyle", create_downloads, true);
