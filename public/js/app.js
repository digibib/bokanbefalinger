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

// set tittel=forfatter som get parameter
$("#search-button").on('click', function() {
	$("#search-input-copy").val($("#search-input").val());
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

	$('#isbn').val('');

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
		}
		$('#isbn-results').show()
	});

	request.fail(function(jqXHR, textStatus, errorThrown) {
		$('#isbn-error').html(isbn_input);
		$('#isbn').prop("disabled", false);
		$('.loading-message').hide();
		$('#isbn-notfound').show();
	});

});