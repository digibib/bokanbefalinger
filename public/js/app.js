// EZPZ Tooltip v1.0; Copyright (c) 2009 Mike Enriquez, http://theezpzway.com; Released under the MIT License
(function($){$.fn.ezpz_tooltip=function(options){var settings=$.extend({},$.fn.ezpz_tooltip.defaults,options);return this.each(function(){var content=$("#"+getContentId(this.id));var targetMousedOver=$(this).mouseover(function(){settings.beforeShow(content,$(this))}).mousemove(function(e){contentInfo=getElementDimensionsAndPosition(content);targetInfo=getElementDimensionsAndPosition($(this));contentInfo=$.fn.ezpz_tooltip.positions[settings.contentPosition](contentInfo,e.pageX,e.pageY,settings.offset,targetInfo);contentInfo=keepInWindow(contentInfo);content.css('top',contentInfo['top']);content.css('left',contentInfo['left']);settings.showContent(content)});if(settings.stayOnContent&&this.id!=""){$("#"+this.id+", #"+getContentId(this.id)).mouseover(function(){content.css('display','block')}).mouseout(function(){content.css('display','none');settings.afterHide()})}else{targetMousedOver.mouseout(function(){settings.hideContent(content);settings.afterHide()})}});function getContentId(targetId){if(settings.contentId==""){var name=targetId.split('-')[0];var id=targetId.split('-')[2];return name+'-content-'+id}else{return settings.contentId}};function getElementDimensionsAndPosition(element){var height=element.outerHeight(true);var width=element.outerWidth(true);var top=$(element).offset().top;var left=$(element).offset().left;var info=new Array();info['height']=height;info['width']=width;info['top']=top;info['left']=left;return info};function keepInWindow(contentInfo){var windowWidth=$(window).width();var windowTop=$(window).scrollTop();var output=new Array();output=contentInfo;if(contentInfo['top']<windowTop){output['top']=windowTop}if((contentInfo['left']+contentInfo['width'])>windowWidth){output['left']=windowWidth-contentInfo['width']}if(contentInfo['left']<0){output['left']=0}return output}};$.fn.ezpz_tooltip.positionContent=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions={aboveRightFollow:function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo}};$.fn.ezpz_tooltip.defaults={contentPosition:'aboveRightFollow',stayOnContent:false,offset:10,contentId:"",beforeShow:function(content){},showContent:function(content){content.show()},hideContent:function(content){content.hide()},afterHide:function(){}}})(jQuery);(function($){$.fn.ezpz_tooltip.positions.aboveFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-(contentInfo['height']/2);contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowRightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.aboveStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']-offset-contentInfo['height'];contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=(targetInfo['top']+(targetInfo['height']/2))-(contentInfo['height']/2);contentInfo['left']=targetInfo['left']+targetInfo['width']+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']+targetInfo['height']+offset;contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo}})(jQuery);

// Vis skrivetips ved musover
$.fn.ezpz_tooltip.positions.centerLeft = function(contentInfo, mouseX, mouseY, offset, targetInfo) {
  contentInfo['top'] = 480;
  contentInfo['left'] = 290;
  return contentInfo;
};
$(".tooltip-target").ezpz_tooltip({
  contentPosition: 'centerLeft',
  stayOnContent: true,
  offset:0
});

 // loading animation
var i = 0;
setInterval(function() {
  i = ++i % 4;
  $("#loading").html(""+Array(i+1).join("."));
}, 500);

// set isbn as query param if searchstring matches only /^[0-9-]/
// set tittel=forfatter som get parameter hvis ikke
$("#search-button").on('click', function() {
	var searchterm = $("#search-input").val();
	if (/^[0-9-]*$/.test(searchterm)) {
		$("#search-input-isbn").val(searchterm);
		$("#search-input").prop("disabled", true);
		$("#search-input-copy").prop("disabled", true);
	} else {
		$("#search-input-copy").val(searchterm);
		$("#search-input-isbn").prop("disabled", true);
	}
});


// Enter = søk
$('#isbn').on('keypress', function(evt) {
	if (evt.which == 13) {
		$("#isbn-button").trigger('click');
	}
});

// Søk etter bok via ISBN
$("#isbn-button").on('click', function() {
	var isbn_input = $('#isbn').val();

	if (isbn == "") {
	 return;
	}

	var request = $.ajax({
	  url: '/work_by_isbn/',
	  type: "GET",
	  data: { isbn: isbn_input },
	  dataType: "json"
	});

	$('#isbn').prop("disabled", true);
	$('.loading-message').show();
	$('#isbn-results').hide()

	request.done(function(data) {
		$('#isbn').val('');
		$('#isbn').prop("disabled", false);
		$('.loading-message').hide();
		$('#isbn-notfound').hide();
		$('#isbn-author').html(data.work[0].author);
		$('#isbn-title').html(data.work[0].title);
		if (data.work[0].cover_url) {
			$('.book-cover').removeClass("gray");
			$('#isbn-cover').html("<img class='cover' src='"+data.work[0].cover_url+"'>");
		} else {
			$('.book-cover').addClass("gray");
			$('#isbn-cover').html("");
		}
		$('#anmeld').attr('href', '/manifestasjon'+data.work[0].manifestation.substr(23)+'/ny');
		$('#isbn-results').show()
	});

	request.fail(function(jqXHR, textStatus, errorThrown) {
		$('#isbn').val('');
		$('#isbn-error').html(isbn_input);
		$('#isbn').prop("disabled", false);
		$('.loading-message').hide();
		$('#isbn-notfound').show();
	});

});


/* Skriv ny anbefaling */



$('#draft').on('click', function(event) {
	//event.preventDefault();
});

$('#publish').on('click', function(event) {
	var missing=0;
	// validering
	$('.required').each(function(i) {
		if (this.value == "") {
			this.className += " missing";
			missing += 1;
		}
	});
	if ($('.audiences:checked').length == 0) {
		$('#audiences-fieldset').addClass("missing");
		missing += 1;
	}

	if (missing > 0) {
		event.preventDefault();
	} else {
		$('#published').val("true");
	}
});

$('#review-form').on('focus', '.required', function () {
if ($(this).hasClass('missing')) {
  $(this).removeClass('missing');
  }
});

$('.audiences').on('change', function(e) {
	$('#audiences-fieldset').removeClass("missing");
});



/* liste-generator logikk */

$('#kriterium-container').on('change', 'select.kriterium', function() {
	var k = $(this).find("option:selected").val();
	var $kdiv = $(this).parents(".kriterium-outer");
	$kdiv.find('.kriterium-inner').remove();
	if (k != "s0") {
		$kdiv.addClass("chosen");
		if ( $('.kriterium-outer:last').hasClass("chosen") ) {
			$('#kriterium-container').append($kdiv.clone().removeClass("chosen"));
		}
		var $kspan = $('.'+k+':last').clone().appendTo($kdiv).show().
			find('.inner-input').chosen({no_results_text: "Ingen treff for"});
	} else {
		$kdiv.removeClass("chosen");
		if ($('.kriterium-outer').not('.chosen').length >= 2) {
			$('.kriterium-outer:last').remove();
		}
	}
});

$('#kriterium-container').on('change', '.inner-input', function() {
	var k = $(this).find("option:selected").val();
	if (k === $(this).find("option:first").val() ) {
		console.log("inner unchosen");
		$(this).parents('.kriterium-inner').removeClass('chosen');
	} else {
		console.log("inner chosen");
		$(this).parents('.kriterium-inner').addClass('chosen');
	}
});

$('#kriterium-container').on('click', 'button.fjern', function() {
	$(this).parents('.kriterium-outer').remove();
});

$('#generate-list').on('click', function() {
	var subjects = [];
	$('.inner-input.emne option:selected').each(function(i, e) {
		if (e.value != "" ) {
			subjects.push(e.value);
		}
	});

	var persons = [];
	$('.inner-input.person option:selected').each(function(i, e) {
		if (e.value != "" ) {
			persons.push(e.value);
		}
	});

	var authors = [];
	$('.forfatter').each(function(i, e) {
		if (e.value != "" ) {
			authors.push(e.value);
		}
	});

	var pages_from = [], pages_to = [];
	$('#kriterium-container input.pages-from').each(function(i, e) {
		e.value == "" ? pages_from.push(0) : pages_from.push(e.value);
	});

	$('#kriterium-container input.pages-to').each(function(i, e) {
		e.value == "" ? pages_to.push(10000) : pages_to.push(e.value);
	});

	var pages = _.zip(pages_from, pages_to);

	var years_from = [], years_to = [];
	$('#kriterium-container input.years-from').each(function(i, e) {
		e.value == "" ? years_from.push(0) : years_from.push(e.value);
	});

	$('#kriterium-container input.years-to').each(function(i, e) {
		e.value == "" ? years_to.push(10000) : years_to.push(e.value);
	});

	var years = _.zip(years_from, years_to);

	var audience = [];
	$('.inner-input.audience option:selected').each(function(i, e) {
		if (e.value != "" ) {
			audience.push(e.value);
		}
	});

	var review_audience = [];
	$('.inner-input.review-audience option:selected').each(function(i, e) {
		if (e.value != "" ) {
			review_audience.push(e.value);
		}
	});

	var genres = [];
	$('.inner-input.genre option:selected').each(function(i, e) {
		if (e.value != "" ) {
			genres.push(e.value);
		}
	});


	var request = $.ajax({
	  url: '/lister',
	  type: "POST",
	  data: { authors: authors, persons: persons, subjects: subjects,
	          pages: JSON.stringify(pages), years: JSON.stringify(years),
	          audience: audience, review_audience: review_audience,
	          genres: genres},
	  dataType: "json"
	});

	$('#list-results').html("Et øyeblikk...");

    function printReviews(element, index, array) {
    	$('#list-results').append('<p>'+element+'</p>');
    }
	request.done(function(data) {
		$('#list-results').html("<h2>"+ data.length +" treff</h2>");
		data.forEach(printReviews);
	});
});

/* Mine anbefalinger */
$('#show-draft').on('click', function() {
	$('#show-draft').removeClass("gray").addClass("red");
	$('#show-published').removeClass("red").addClass("gray");
	$('.published').hide();
	$('.draft').show();
});

$('#show-published').on('click', function() {
	$('#show-published').removeClass("gray").addClass("red");
	$('#show-draft').removeClass("red").addClass("gray");
	$('.draft').hide();
	$('.published').show();
});
