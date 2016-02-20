$(document).ready(function() {
  $(".artist-image img").hover(
    function () {
      $('div.artist-name').html($(this).attr('title'));
    }
  );

  var artistImageLinks = $('.artists').find('a.artist-image');
  for(var i=0; i< artistImageLinks.length; i++) {
    loadImage(artistImageLinks[i]);
  }

  function loadImage(element) {
    if (element.href != '') {
      var mbid = element.href.split('/').pop();
      $.get("/api/artists/"+mbid+"/image.json", function(json) {
        if (json['url'] != null) {
          $('#'+mbid).attr("src", json['url']);
        }
      });
    }
  }
});