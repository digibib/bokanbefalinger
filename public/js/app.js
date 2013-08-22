// EZPZ Tooltip v1.0; Copyright (c) 2009 Mike Enriquez, http://theezpzway.com; Released under the MIT License
(function($){$.fn.ezpz_tooltip=function(options){var settings=$.extend({},$.fn.ezpz_tooltip.defaults,options);return this.each(function(){var content=$("#"+getContentId(this.id));var targetMousedOver=$(this).mouseover(function(){settings.beforeShow(content,$(this))}).mousemove(function(e){contentInfo=getElementDimensionsAndPosition(content);targetInfo=getElementDimensionsAndPosition($(this));contentInfo=$.fn.ezpz_tooltip.positions[settings.contentPosition](contentInfo,e.pageX,e.pageY,settings.offset,targetInfo);contentInfo=keepInWindow(contentInfo);content.css('top',contentInfo['top']);content.css('left',contentInfo['left']);settings.showContent(content)});if(settings.stayOnContent&&this.id!=""){$("#"+this.id+", #"+getContentId(this.id)).mouseover(function(){content.css('display','block')}).mouseout(function(){content.css('display','none');settings.afterHide()})}else{targetMousedOver.mouseout(function(){settings.hideContent(content);settings.afterHide()})}});function getContentId(targetId){if(settings.contentId==""){var name=targetId.split('-')[0];var id=targetId.split('-')[2];return name+'-content-'+id}else{return settings.contentId}};function getElementDimensionsAndPosition(element){var height=element.outerHeight(true);var width=element.outerWidth(true);var top=$(element).offset().top;var left=$(element).offset().left;var info=new Array();info['height']=height;info['width']=width;info['top']=top;info['left']=left;return info};function keepInWindow(contentInfo){var windowWidth=$(window).width();var windowTop=$(window).scrollTop();var output=new Array();output=contentInfo;if(contentInfo['top']<windowTop){output['top']=windowTop}if((contentInfo['left']+contentInfo['width'])>windowWidth){output['left']=windowWidth-contentInfo['width']}if(contentInfo['left']<0){output['left']=0}return output}};$.fn.ezpz_tooltip.positionContent=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions={aboveRightFollow:function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo}};$.fn.ezpz_tooltip.defaults={contentPosition:'aboveRightFollow',stayOnContent:false,offset:10,contentId:"",beforeShow:function(content){},showContent:function(content){content.show()},hideContent:function(content){content.hide()},afterHide:function(){}}})(jQuery);(function($){$.fn.ezpz_tooltip.positions.aboveFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-(contentInfo['height']/2);contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowRightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.aboveStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']-offset-contentInfo['height'];contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=(targetInfo['top']+(targetInfo['height']/2))-(contentInfo['height']/2);contentInfo['left']=targetInfo['left']+targetInfo['width']+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']+targetInfo['height']+offset;contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo}})(jQuery);

/* TinySort 1.4.29
* Copyright (c) 2008-2012 Ron Valstar http://www.sjeiti.com */
(function(c){var e=!1,f=null,j=parseFloat,g=Math.min,i=/(-?\d+\.?\d*)$/g,h=[],d=[];c.tinysort={id:"TinySort",version:"1.4.29",copyright:"Copyright (c) 2008-2012 Ron Valstar",uri:"http://tinysort.sjeiti.com/",licensed:{MIT:"http://www.opensource.org/licenses/mit-license.php",GPL:"http://www.gnu.org/licenses/gpl.html"},plugin:function(k,l){h.push(k);d.push(l)},defaults:{order:"asc",attr:f,data:f,useVal:e,place:"start",returns:e,cases:e,forceStrings:e,sortFunction:f}};c.fn.extend({tinysort:function(o,k){if(o&&typeof(o)!="string"){k=o;o=f}var p=c.extend({},c.tinysort.defaults,k),u,D=this,z=c(this).length,E={},r=!(!o||o==""),s=!(p.attr===f||p.attr==""),y=p.data!==f,l=r&&o[0]==":",m=l?D.filter(o):D,t=p.sortFunction,x=p.order=="asc"?1:-1,n=[];c.each(h,function(G,H){H.call(H,p)});if(!t){t=p.order=="rand"?function(){return Math.random()<0.5?1:-1}:function(O,M){var N=e,J=!p.cases?a(O.s):O.s,I=!p.cases?a(M.s):M.s;if(!p.forceStrings){var H=J&&J.match(i),P=I&&I.match(i);if(H&&P){var L=J.substr(0,J.length-H[0].length),K=I.substr(0,I.length-P[0].length);if(L==K){N=!e;J=j(H[0]);I=j(P[0])}}}var G=x*(J<I?-1:(J>I?1:0));c.each(d,function(Q,R){G=R.call(R,N,J,I,G)});return G}}D.each(function(I,J){var K=c(J),G=r?(l?m.filter(J):K.find(o)):K,L=y?""+G.data(p.data):(s?G.attr(p.attr):(p.useVal?G.val():G.text())),H=K.parent();if(!E[H]){E[H]={s:[],n:[]}}if(G.length>0){E[H].s.push({s:L,e:K,n:I})}else{E[H].n.push({e:K,n:I})}});for(u in E){E[u].s.sort(t)}for(u in E){var A=E[u],C=[],F=z,w=[0,0],B;switch(p.place){case"first":c.each(A.s,function(G,H){F=g(F,H.n)});break;case"org":c.each(A.s,function(G,H){C.push(H.n)});break;case"end":F=A.n.length;break;default:F=0}for(B=0;B<z;B++){var q=b(C,B)?!e:B>=F&&B<F+A.s.length,v=(q?A.s:A.n)[w[q?0:1]].e;v.parent().append(v);if(q||!p.returns){n.push(v.get(0))}w[q?0:1]++}}D.length=0;Array.prototype.push.apply(D,n);return D}});function a(k){return k&&k.toLowerCase?k.toLowerCase():k}function b(m,p){for(var o=0,k=m.length;o<k;o++){if(m[o]==p){return !e}}return e}c.fn.TinySort=c.fn.Tinysort=c.fn.tsort=c.fn.tinysort})(jQuery);
/* Array.prototype.indexOf for IE (issue #26) */
if(!Array.prototype.indexOf){Array.prototype.indexOf=function(b){var a=this.length,c=Number(arguments[1])||0;c=c<0?Math.ceil(c):Math.floor(c);if(c<0){c+=a}for(;c<a;c++){if(c in this&&this[c]===b){return c}}return -1}};

/* HTML5 Sortable (http://farhadi.ir/projects/html5sortable)
 * Released under the MIT license.
 */(function(a){var b,c=a();a.fn.sortable=function(d){var e=String(d);return d=a.extend({connectWith:!1},d),this.each(function(){if(/^enable|disable|destroy$/.test(e)){var f=a(this).children(a(this).data("items")).attr("draggable",e=="enable");e=="destroy"&&f.add(this).removeData("connectWith items").off("dragstart.h5s dragend.h5s selectstart.h5s dragover.h5s dragenter.h5s drop.h5s");return}var g,h,f=a(this).children(d.items),i=a("<"+(/^ul|ol$/i.test(this.tagName)?"li":"div")+' class="sortable-placeholder">');f.find(d.handle).mousedown(function(){g=!0}).mouseup(function(){g=!1}),a(this).data("items",d.items),c=c.add(i),d.connectWith&&a(d.connectWith).add(this).data("connectWith",d.connectWith),f.attr("draggable","true").on("dragstart.h5s",function(c){if(d.handle&&!g)return!1;g=!1;var e=c.originalEvent.dataTransfer;e.effectAllowed="move",e.setData("Text","dummy"),h=(b=a(this)).addClass("sortable-dragging").index()}).on("dragend.h5s",function(){b.removeClass("sortable-dragging").show(),c.detach(),h!=b.index()&&f.parent().trigger("sortupdate",{item:b}),b=null}).not("a[href], img").on("selectstart.h5s",function(){return this.dragDrop&&this.dragDrop(),!1}).end().add([this,i]).on("dragover.h5s dragenter.h5s drop.h5s",function(e){return!f.is(b)&&d.connectWith!==a(b).parent().data("connectWith")?!0:e.type=="drop"?(e.stopPropagation(),c.filter(":visible").after(b),!1):(e.preventDefault(),e.originalEvent.dataTransfer.dropEffect="move",f.is(this)?(d.forcePlaceholderSize&&i.height(b.outerHeight()),b.hide(),a(this)[i.index()<a(this).index()?"after":"before"](i),c.not(i).detach()):!c.is(this)&&!a(this).children(d.items).length&&(c.detach(),a(this).append(i)),!1)})})}})(jQuery);
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


// function to send an request to store my-list in the session object
function storeList(id) {
	var list_uri = 'http://data.deichman.no/mylist/'+id;
	var $list = $('#'+id);
	var label = $list.find('.liste-navn').val();
	var items = [];
	$list.find('.mylist-review').each(function() {
		items.push({ title: $(this).text(),
		             uri: "http://data.deichman.no"+ $(this).attr("href").substr(11) });
	});

	$.ajax({
		type: "POST",
		url: '/mylist',
		data: {uri: list_uri, items: JSON.stringify(items), label: label}
	});

	setTimeout(function() {
		// Autosave list
		if ( id != "id_new") {
			$list.find('.save-list').click();
		}
	}, 100); // make sure list is stored in session before saving

}

// My list logic
$('document').ready(function() {
	// Reload list on mouse over, in case of user uses the back buttond
	var mylists_refreshed = false;
	$('#mylists-container').mouseover(function() {
		if (!mylists_refreshed) {
			//console.log("reloading mylists");
			// remember if a list is open
			var openid = $('.mytriangle.close').parents('.single-list').attr('id');
			// console.log(openid);
			$('#mylists-container').load('/refreshmylists');
			$('#mylists-container').ajaxStop(function() {
			 	$('#'+openid).find('.myliste-innhold').show().end().find('.mytriangle').removeClass('open').addClass('close');
			});
		}
		mylists_refreshed = true;

	});

	// Show dropdown to select which list to add to
	$('.main-left').on('click', 'button.pluss', function() {
		$(this).parents('.mylist-parent').find('.select-list').show();
	});

	// Add to my list
	$('.main-left').on('click', 'button.add-to-list', function() {
		var uri = $(this).parents('.uri-title').find('input.uri').val();
		var title = $(this).parents('.uri-title').find('input.title').val();

		var which_list = $(this).parents('.select-list').find('option:selected').val().substr(31);

		if ( ( $('#id_new').length == 0 ) && ( which_list == "id_new" ) ) {
			var $list = $('.template-list').clone().removeClass('template-list');
			$list.attr("id", "id_new");
			$list.prependTo('.my-lists').show();
			$("option[value='http://data.deichman.no/mylist/id_new']").text("Uten tittel");
		} else {
			var $list = $("#" + which_list);
		}

		// open list if not open
		if ( $list.find('.mytriangle').hasClass('open')) {
			$list.find('.mytriangle').trigger('click');
		}

		// append review to list
		$list.find('ol').append('<li><a class="mylist-review" href="/anbefaling/' + uri.substr(24) +'">'+title+'</a><a class="remove">x</a></li>');

		// refresh drag and sort
		$('.sortable').sortable();
		storeList($list.attr('id'));

		$('#mylist-box').addClass('highlight');
		setTimeout(function() {
			$('#mylist-box').removeClass('highlight');
		}, 2500);

		// Hide select dropdown
		$(this).parents('.mylist-parent').find('.select-list').hide();
	});

	// Cancel add to my list
	$('.main-left').on('click', 'button.cancel-add-to-list', function() {
		$(this).parents('.mylist-parent').find('.select-list').hide();
	});

	// remove review on click 'x'
	$('#mylists-container').on('click', '.remove', function() {
		var list_id = $(this).parents('.single-list').attr('id');
		$(this).parents('li').remove();
		storeList(list_id);
	});

	// Show list when clicking on title or triangle
	$('#mylists-container').on('click', '.mytriangle.close', function() {
		$(this).removeClass("close").addClass("open");
		$(this).next().next().slideUp();
	});

	// open/close list
	$('#mylists-container').on('click', '.mytriangle.open', function() {
		$('.myliste-innhold').slideUp();
		$('.mytriangle.close').removeClass("close").addClass("open");
		$(this).removeClass("open").addClass("close");
		$(this).next().next().slideDown();
	});

	$('#mylists-container').on('click', '.myliste-tittel', function() {
		$(this).next().click();
	});

	// edit list title
	$('#mylists-container').on('click', '.edit-list-title', function() {
		// hide link and show input
		$(this).parents('.mylist-buttons').hide();
		$(this).parents('.single-list').find('.edit-title').show();
	});

	// copy rss link
	$('#mylists-container').on('click', '.mylist-rss-copy', function() {
		window.prompt("Trykk Ctrl+C, så Enter for å kopiere", $(this).parents(".single-list").find(".mylist-rss-link").val());
	});

	// Save list
	$('#mylists-container').on('click', '.save-list', function() {
		var $btn = $(this);
		$btn.html("<img style='height:12px' src='/img/loading.gif'>");
		var $list = $(this).parents('.single-list');
		var uri = $list.attr('id');

		var label = $list.find('.liste-navn').val();
		var items = [];
		$list.find('.mylist-review').each(function() {
			items.push({ title: $(this).text(),
			             uri: "http://data.deichman.no"+ $(this).attr("href").substr(11) });
		});

		var request = $.ajax({
			type: "POST",
			url: '/savemylist',
			dataType: "json",
			data: { uri: "http://data.deichman.no/mylist/" + uri, items: JSON.stringify(items), label: label},
		});


		request.done(function(data) {
			// list saved
			$btn.html("lagre");
			$list.find('.myliste-tittel').html(label);
			$list.attr("id", (data.uri.substr(31)));
			$list.find('.edit-title').hide();
			$list.find('.mylist-buttons').show()
			$list.find('.edit-list-title').show();
			$list.find(".mylist-rss-link").val("http://anbefalinger.deichman.no/feed?list=" + data.uri+ "&title=" + data.label);
			$list.find('.mylist-rss-copy').show();

			if (uri == "id_new") {
				// add new list to dropdown, and change "uten tittel" to "lag ny liste"
				$('.select-list-list').append("<option value='" + data.uri + "'>" + data.label + "</option>");
				$("option[value='http://data.deichman.no/mylist/id_new']").text("Lag ny liste");
			}
		})

	});

	// Delete list
	$('#mylists-container').on('click', '.delete-list', function() {
		var $list = $(this).parents('.single-list');
		var uri = $list.attr('id');

		var request = $.ajax({
			type: "POST",
			url: '/deletemylist',
			data: { uri: "http://data.deichman.no/mylist/" + uri},
		});


		request.done(function() {
			$list.remove();
			// remove from add-to-list dropdowns
			$("option[value='http://data.deichman.no/mylist/"+uri+"']").remove();

			// add new "lag ny liste" if the removed list was unsaved
			if (uri == 'id_new') {
				$('.select-list-list').append("<option value='http://data.deichman.no/mylist/id_new'>Lag ny liste</option>");
			}
		})

	});

});