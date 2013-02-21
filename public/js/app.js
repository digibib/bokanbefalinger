// EZPZ Tooltip v1.0; Copyright (c) 2009 Mike Enriquez, http://theezpzway.com; Released under the MIT License
(function($){$.fn.ezpz_tooltip=function(options){var settings=$.extend({},$.fn.ezpz_tooltip.defaults,options);return this.each(function(){var content=$("#"+getContentId(this.id));var targetMousedOver=$(this).mouseover(function(){settings.beforeShow(content,$(this))}).mousemove(function(e){contentInfo=getElementDimensionsAndPosition(content);targetInfo=getElementDimensionsAndPosition($(this));contentInfo=$.fn.ezpz_tooltip.positions[settings.contentPosition](contentInfo,e.pageX,e.pageY,settings.offset,targetInfo);contentInfo=keepInWindow(contentInfo);content.css('top',contentInfo['top']);content.css('left',contentInfo['left']);settings.showContent(content)});if(settings.stayOnContent&&this.id!=""){$("#"+this.id+", #"+getContentId(this.id)).mouseover(function(){content.css('display','block')}).mouseout(function(){content.css('display','none');settings.afterHide()})}else{targetMousedOver.mouseout(function(){settings.hideContent(content);settings.afterHide()})}});function getContentId(targetId){if(settings.contentId==""){var name=targetId.split('-')[0];var id=targetId.split('-')[2];return name+'-content-'+id}else{return settings.contentId}};function getElementDimensionsAndPosition(element){var height=element.outerHeight(true);var width=element.outerWidth(true);var top=$(element).offset().top;var left=$(element).offset().left;var info=new Array();info['height']=height;info['width']=width;info['top']=top;info['left']=left;return info};function keepInWindow(contentInfo){var windowWidth=$(window).width();var windowTop=$(window).scrollTop();var output=new Array();output=contentInfo;if(contentInfo['top']<windowTop){output['top']=windowTop}if((contentInfo['left']+contentInfo['width'])>windowWidth){output['left']=windowWidth-contentInfo['width']}if(contentInfo['left']<0){output['left']=0}return output}};$.fn.ezpz_tooltip.positionContent=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions={aboveRightFollow:function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX+offset;return contentInfo}};$.fn.ezpz_tooltip.defaults={contentPosition:'aboveRightFollow',stayOnContent:false,offset:10,contentId:"",beforeShow:function(content){},showContent:function(content){content.show()},hideContent:function(content){content.hide()},afterHide:function(){}}})(jQuery);(function($){$.fn.ezpz_tooltip.positions.aboveFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-offset-contentInfo['height'];contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY-(contentInfo['height']/2);contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowRightFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowFollow=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=mouseY+offset;contentInfo['left']=mouseX-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.aboveStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']-offset-contentInfo['height'];contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo};$.fn.ezpz_tooltip.positions.rightStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=(targetInfo['top']+(targetInfo['height']/2))-(contentInfo['height']/2);contentInfo['left']=targetInfo['left']+targetInfo['width']+offset;return contentInfo};$.fn.ezpz_tooltip.positions.belowStatic=function(contentInfo,mouseX,mouseY,offset,targetInfo){contentInfo['top']=targetInfo['top']+targetInfo['height']+offset;contentInfo['left']=(targetInfo['left']+(targetInfo['width']/2))-(contentInfo['width']/2);return contentInfo}})(jQuery);

/* TinySort 1.4.29
* Copyright (c) 2008-2012 Ron Valstar http://www.sjeiti.com */
(function(c){var e=!1,f=null,j=parseFloat,g=Math.min,i=/(-?\d+\.?\d*)$/g,h=[],d=[];c.tinysort={id:"TinySort",version:"1.4.29",copyright:"Copyright (c) 2008-2012 Ron Valstar",uri:"http://tinysort.sjeiti.com/",licensed:{MIT:"http://www.opensource.org/licenses/mit-license.php",GPL:"http://www.gnu.org/licenses/gpl.html"},plugin:function(k,l){h.push(k);d.push(l)},defaults:{order:"asc",attr:f,data:f,useVal:e,place:"start",returns:e,cases:e,forceStrings:e,sortFunction:f}};c.fn.extend({tinysort:function(o,k){if(o&&typeof(o)!="string"){k=o;o=f}var p=c.extend({},c.tinysort.defaults,k),u,D=this,z=c(this).length,E={},r=!(!o||o==""),s=!(p.attr===f||p.attr==""),y=p.data!==f,l=r&&o[0]==":",m=l?D.filter(o):D,t=p.sortFunction,x=p.order=="asc"?1:-1,n=[];c.each(h,function(G,H){H.call(H,p)});if(!t){t=p.order=="rand"?function(){return Math.random()<0.5?1:-1}:function(O,M){var N=e,J=!p.cases?a(O.s):O.s,I=!p.cases?a(M.s):M.s;if(!p.forceStrings){var H=J&&J.match(i),P=I&&I.match(i);if(H&&P){var L=J.substr(0,J.length-H[0].length),K=I.substr(0,I.length-P[0].length);if(L==K){N=!e;J=j(H[0]);I=j(P[0])}}}var G=x*(J<I?-1:(J>I?1:0));c.each(d,function(Q,R){G=R.call(R,N,J,I,G)});return G}}D.each(function(I,J){var K=c(J),G=r?(l?m.filter(J):K.find(o)):K,L=y?""+G.data(p.data):(s?G.attr(p.attr):(p.useVal?G.val():G.text())),H=K.parent();if(!E[H]){E[H]={s:[],n:[]}}if(G.length>0){E[H].s.push({s:L,e:K,n:I})}else{E[H].n.push({e:K,n:I})}});for(u in E){E[u].s.sort(t)}for(u in E){var A=E[u],C=[],F=z,w=[0,0],B;switch(p.place){case"first":c.each(A.s,function(G,H){F=g(F,H.n)});break;case"org":c.each(A.s,function(G,H){C.push(H.n)});break;case"end":F=A.n.length;break;default:F=0}for(B=0;B<z;B++){var q=b(C,B)?!e:B>=F&&B<F+A.s.length,v=(q?A.s:A.n)[w[q?0:1]].e;v.parent().append(v);if(q||!p.returns){n.push(v.get(0))}w[q?0:1]++}}D.length=0;Array.prototype.push.apply(D,n);return D}});function a(k){return k&&k.toLowerCase?k.toLowerCase():k}function b(m,p){for(var o=0,k=m.length;o<k;o++){if(m[o]==p){return !e}}return e}c.fn.TinySort=c.fn.Tinysort=c.fn.tsort=c.fn.tinysort})(jQuery);
/* Array.prototype.indexOf for IE (issue #26) */
if(!Array.prototype.indexOf){Array.prototype.indexOf=function(b){var a=this.length,c=Number(arguments[1])||0;c=c<0?Math.ceil(c):Math.floor(c);if(c<0){c+=a}for(;c<a;c++){if(c in this&&this[c]===b){return c}}return -1}};

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
	if (/^[0-9-xX]*$/.test(searchterm)) {
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

$('#delete-button').on('click', function(event) {
	$('#delete').val("delete");
});


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

// Ikke vis 'legg til kriterium' før noe kriterium er valgt
$('.kriterium-add').hide();

$('#add-kriterium').on('click', function() {
	var $kdiv = $(".kriterium-outer:first").clone();
	$kdiv.find('.kriterium-inner').remove().end().
		find(':input').prop('disabled', false);
	if ( $('.kriterium-outer:last').hasClass("chosen") ) {
		$('#kriterium-container').append($kdiv.removeClass("chosen"));
	}
	// Lås tidligere kriterier
	$('.kriterium-outer:not(:last-child)').find(':input').prop('disabled', true).
		trigger("liszt:updated");
	// Skjul legg-til knappen
	$('.kriterium-add').hide();
});

$('#kriterium-container').on('change', 'select.kriterium', function() {
	var k = $(this).find("option:selected").val();
	var $kdiv = $(this).parents(".kriterium-outer");
	$kdiv.find('.kriterium-inner').remove();
	if (k != "s0") {
		$kdiv.addClass("chosen");
		var $kspan = $('.'+k+':last').clone().appendTo($kdiv).show().
			find('.inner-input').chosen({no_results_text: "Ingen treff for"});

		// Ikke vis 'fjern' knapp hvis det er bare ett kriterium
		if ( $('.kriterium-outer').length <= 1 ) {
			$('.fjern').hide();
		} else {
			$('.fjern').show();
		}
	} else {
		$kdiv.removeClass("chosen");
		$('.kriterium-add').hide();
		if ($('.kriterium-outer').not('.chosen').length >= 2) {
			$('.kriterium-outer:last').remove();
		}
	}
});

$('#kriterium-container').on('change', '.inner-input', function() {
	var k = $(this).find("option:selected").val();
	if (k === $(this).find("option:first").val() ) {
		$(this).parents('.kriterium-inner').removeClass('chosen');
		// Skjul 'legg til kriterium'
		$('.kriterium-add').hide();
	} else {
		$(this).parents('.kriterium-inner').addClass('chosen');
		// Vis 'legg til kriterium'
		$('.kriterium-add').show();
	}
});

$('#kriterium-container').on('click', 'button.fjern', function() {
	$(this).parents('.kriterium-outer').remove();
	// Ikke vis 'fjern' knapp hvis det er bare ett kriterium
	if ( $('.kriterium-outer').length <= 1 ) {
		$('.fjern').hide();
	} else {
		$('.fjern').show();
	}
	// Lås opp siste kriterium
	$('.kriterium-outer:last').find(':input').prop('disabled', false).
		trigger("liszt:updated");
});

// Skjul 'legg til kriterium' hvis input felt er tomme
$('#kriterium-container').on('keyup', 'input.number', function() {
	var v="";
	$(this).parents('.kriterium-inner').find('input[type="text"]')
	  .each(function() {
	  	v+=$(this).val();
	  });
	if ( v != "" ) {
		$('.kriterium-add').show();
	} else {
		$('.kriterium-add').hide();
	}
});

// Reset alle kriterier
$('#reset-krierier').on('click', function() {
	$('.kriterium-outer :not(:first)').remove();
	$('.kriterium-outer:first').find('.kriterium-inner').remove();
	$('.kriterium-outer:first').find('option:first').prop('selected', true).end()
		.find(':input').prop('disabled', false);
	$('.kriterium-add').hide();
});

function collectCriteria() {
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

	var languages = [];
	$('.inner-input.language option:selected').each(function(i, e) {
		if (e.value != "" ) {
			languages.push(e.value);
		}
	});

	var formats = [];
	$('.inner-input.litform option:selected').each(function(i, e) {
		if (e.value != "" ) {
			formats.push(e.value);
		}
	});

	var nationalities = [];
	$('.inner-input.nasjonalitet option:selected').each(function(i, e) {
		if (e.value != "" ) {
			nationalities.push(e.value);
		}
	});

	return { authors: authors, persons: persons, subjects: subjects,
	          pages: JSON.stringify(pages), years: JSON.stringify(years),
	          audience: audience, review_audience: review_audience,
	          genres: genres, languages: languages, formats: formats,
	          nationalities: nationalities}
}

$('#generate-list').on('click', function() {
	data = collectCriteria();

	var request = $.ajax({
	  url: '/lister',
	  type: "POST",
	  data: data,
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

// sortering:
$('#my-reviews-sorting').on('change', function() {
	$("#my-reviews-list > div:visible").tsort('',{attr:'timestamp', order:$('#my-reviews-sorting option:selected').val()});
});


// Brukerinnstillinger - validering

function validateEmail($email)
  {
  	var emailReg = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/;
  	return emailReg.test( $email );
  }

$('#lagre-innstillinger').on('click', function(event) {
	// valider epostadresse
	var validationFail = false;
	$('span.error').hide();

	var email = $('#email').val();
	var oldemail = $('#oldemail').val();
	if (email) {
		if (!validateEmail(email)) {
			$('.email-validation').html("Ugyldig epostadresse").show();
			validationFail = true;
		}
	}

	// kontroller at passordene er like
	var passord1 = $('#passord1').val();
	var passord2 = $('#passord2').val();
	if (passord1 != passord2) {
		$('.password-validation').html("Passordene er ikke like").show();
		validationFail = true;
	}

	// Ikke noe å lagre?
	if ( !validationFail && !passord1 && !passord2 && (email === oldemail ) ) {
		$('span.error').html("Ingen endringer").show();
		validationFail = true;
	}

	if ( validationFail ) {
		event.preventDefault();
	}
})