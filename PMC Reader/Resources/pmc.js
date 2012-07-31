
function docTitle() {
    var divArray = document.getElementsByTagName("h1");
    for (var i = 0; i < divArray.length; i++){
        if (divArray[i].class="content-title") {
            var tmp = document.createElement("DIV");
            tmp.innerHTML = divArray[i].innerHTML;
            return tmp.textContent||tmp.innerText;

        }
    }
}


