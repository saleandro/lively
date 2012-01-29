$(window).load(function () {
	
	var colours = [[251,175,93], [135,129,190],[171,160,0], [114,173,170], [255,242,0], [246,152,157], [141, 198,63], [237, 28,36] ];
	var backgrounds = [];
	var total = 0;
	var other = 0;
	
	$('.top-terms').each(function(){
		//find the maximum and the total
		
		//alert("max:" + mx + " total:" + total + " count:" + count + " min:" + mn);
		
		var height = $('#person').height();
		//alert(height);
		
		var counter = 0;
		var start = 0; // % where to start the gradient
		
		$('.top-terms').hide();
		
		$(this).find('li').each(function(){
			if(counter >= colours.length){ counter = 0; }
			total += parseFloat( $(this).attr('class').replace(/[^0-9_]/g, '').replace(/_/g, '.'));
			
			var percent =  parseFloat( $(this).attr('class').replace(/[^0-9_]/g, '').replace(/_/g, '.'));
			
			if( parseFloat( $(this).attr('class').replace(/[^0-9_]/g, '').replace(/_/g, '.')) > 1 ){ 
			  $("#key").append('<div>' + $(this).html() + '</div>');
			  $("#key div:last").css({
				  'color' : 'rgb(' + colours[counter][0] + ',' + colours[counter][1] + ',' + colours[counter][2] + ')',
				  'height' : (parseInt(percent * height / 100 )),
				  'overflow': 'hidden',
				  'font-size':'11px',
			  });
			}
			
			if( parseFloat( $(this).attr('class').replace(/[^0-9_]/g, '').replace(/_/g, '.')) > 1 ){
			
			  //add the background
			  backgrounds.push([colours[counter], start ]);
  
			  start += parseInt( percent );
			  backgrounds.push([colours[counter], start ]); 
			} else {
				other += parseFloat( $(this).attr('class').replace(/[^0-9_]/g, '').replace(/_/g, '.'));
			}
			counter++;
			
		}); // end each td
		
		// other
		// backgrounds.push([colours[counter], start ]);
		
		
		// make background
		var background = ' ';
		// FF
		background += ' background: -moz-linear-gradient(top';
		for(i=0; i < backgrounds.length; i++){
			background += ', rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1) ' + 
					backgrounds[i][1] + '%' ;
		}
		background+= ');';
		
		// webkit
		background += ' background: -webkit-gradient(linear, left top, left bottom';
		for(i=0; i < backgrounds.length; i++){
			background += ', color-stop(' + backgrounds[i][1] + '%, rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1))' ;
		}
		background+= ');';
		
		// chrome 10+
		background += ' background: -webkit-linear-gradient(top';
		for(i=0; i < backgrounds.length; i++){
			background += ', rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1) ' + 
					backgrounds[i][1] + '%' ;
		}
		background+= ');';
		
		//opera
		background += ' background: -o-linear-gradient(top';
		for(i=0; i < backgrounds.length; i++){
			background += ', rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1) ' + 
					backgrounds[i][1] + '%' ;
		}
		background+= ');';
		
		//IE10+ 
		background += ' background: -ms-linear-gradient(top';
		for(i=0; i < backgrounds.length; i++){
			background += ', rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1) ' + 
					backgrounds[i][1] + '%' ;
		}
		background+= ');';
		
		//w3c
		background += ' background: linear-gradient(top';
		for(i=0; i < backgrounds.length; i++){
			background += ', rgba(' + backgrounds[i][0][0] + ',' + backgrounds[i][0][1] + ',' + backgrounds[i][0][2] +', 1) ' + 
					backgrounds[i][1] + '%' ;
		}
		background+= ');';
		
		
		//alert(background);
		alert(total);
		$('#person').attr('style', $('#person').attr('style') + background);
		//background: -moz-linear-gradient(top, rgba(243,197,189,1) 0%, rgba(232,108,87,1) 50%, rgba(234,40,3,1) 51%, rgba(255,102,0,1) 75%, rgba(199,34,0,1) 100%); 
		
	}); //end each heatmap
});

