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
		$('#isbn-author').html(data.author);
		$('#isbn-title').html(data.title);
		if (data.work_title != data.title) {
			$('#isbn-work-title').html("(originaltittel: "+data.work_title+")");
		}
		if (data.cover_url) {
			$('.book-cover').removeClass("gray");
			$('#isbn-cover').html("<img class='cover' src='"+data.cover_url+"'>");
		} else {
			$('.book-cover').addClass("gray");
			$('#isbn-cover').html("");
		}
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

	var pages_from = new Array();
	$('#kriterium-container input.pages-from').each(function(i, e) {
		var v;
		if (e.value == "") {
			pages_from.push(0);
		} else {
			pages_from.push(e.value);
		}
	});
	var pages_to = new Array();
	$('#kriterium-container input.pages-to').each(function(i, e) {
		var v;
		if (e.value == "") {
			pages_to.push(10000);
		} else {
			pages_to.push(e.value);
		}
	});

	var pages = _.zip(pages_from, pages_to);

	var request = $.ajax({
	  url: '/lister',
	  type: "POST",
	  data: { authors: authors, persons: persons, subjects: subjects,
	          pages: JSON.stringify(pages) },
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

