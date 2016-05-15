var crumbs = []

$(document).ready(function()
{
	for (object in objects) {
		var target = undefined;

		if (objects[object].objType == 'functions') {
			if (objects[object].kind == 'forward') {
				target = $('#forwards');
			} else {
				target = $('#functions');
			}
		} else if (objects[object].objType == 'typedefs') {
			target = $('#types');
		} else if (objects[object].objType == 'enums') {
			target = $('#types');
		} else if (objects[object].objType == 'constants') {
			target = $('#constants');
		}

		if (target == undefined)
			continue;

		var lst = target.html();

		var doc = '';
		if ('docText' in objects[object]) {
			doc = objects[object].docText.replace(/<(?:.|\n)*?>/gm, '');
			doc = doc.replace(/"/g, '&quot;');
		}

		lst += '<li id="' + object + '" data-container="body" data-trigger="hover" data-title="' + object + '" data-content="' + doc + '">';
			lst += '<a href="#" onclick="loadObjectDetails(\'' + object + '\'); return false;">';
				lst += object;
			lst += '</a>';
		lst += '</li>';

		target.html(lst);
	}

	$('#search').on('change paste keyup', function(){
		var value = $('#search').val();
		var valueLength = value.length;

		if (valueLength > 2) {
			search(value);
			$('#search-clear').show();
		} else if (valueLength > 0) {
			$("#objects li").show();
			$('#search-clear').show();
		} else {
			$("#objects li").show();
			$('#search-clear').hide();
		}
	});

	$('#objects li').popover();

	var url = $(location).attr('href');
	var questionMark = url.indexOf('?');

	if (questionMark == -1) {
		loadMainPage();
	} else {
		name = url.substring(questionMark + 1);
		loadObjectDetails(name);
	}
});

function loadObjectDetails(object)
{
	var details = '';

	switch (objects[object].objType) {
		case 'functions':
			details = loadFunctionDetails(object, objects[object])
			break;
		case 'typedefs':
			details = loadTypedefDetails(object, objects[object])
			break;
		case 'enums':
			details = loadEnumDetails(object, objects[object])
			break;
		case 'constants':
			details = loadConstantDetails(object, objects[object])
			break;
	}

	$('#objectDetail').html(details);

	$('#objects li').removeClass('active');
	$('#' + object).addClass('active');

	var url = location.href;
	var questionMark = url.indexOf('?');

	if (questionMark != -1) {
		url = url.substring(0, questionMark);
	}

	window.history.replaceState({} , document.title, url + '?' + object);

	$(document).prop('title', 'TG API | ' + object);

	updateBreadCrumbs(object)
}

function loadFunctionDetails(name, obj)
{
	var details = '';

	details += '<h1 class="page-header">' + name + ' <span class="kind">' + capitalizeFirstLetter(obj.kind) + '</span>' + '</h1>';

	details += buildFunctionHeader(name, obj);

	details += '<h4 class="sub-header2">Description</h4>';
	details += '<p style="margin-left: 30px;">';
	if ('docText' in obj) {
		details += obj.docText
	} else {
		details += '<i class="text-muted">This function has no description.</i>';
	}
	details += '</p>';

	if (obj.arguments.length > 0) {
		details += '<h4 class="sub-header2">Parameters</h4>';
		details += '<dl style="margin-left: 30px;">';

		for (i in obj.arguments) {
			var arg = obj.arguments[i];
			details += '<div style="margin-bottom: 20px;">';
			details += '<dt class="mono">';
			details += '<span class="type">' + getTypeName(arg.type) + '</span>';

			if ('byReference' in arg) {
				details += '<span class="byReference">&</span>';
			}

			details += ' <span class="name">' + arg.name + '</span>';

			if ('defaultValue' in arg) {
				details += '<span class="defaultValue"> = ' + arg.defaultValue + '</span>';
			}

			details += '</dt>';

			details += '<dd>';
			if ('docText' in arg) {
				details += arg.docText
			} else {
				details += '<i class="text-muted">No description.</i>';
			}
			details += '</dd>';

			details += '</div>';
		}

		details += '</dl>';

		if ('returnDoc' in obj) {
			details += '<div class="bs-callout bs-callout-info">';
			details += '<h4>Return Value</h4>';
			details += '<p>' + obj.returnDoc + '<p>';
			details += '</div>';
		}
	}

	return details;
}

function buildFunctionHeader(objName, obj)
{
	var header = '<pre class="syntax mono">';

	if (obj.returnType != 'void') {
		header += '<span class="type">' + getTypeName(obj.returnType) + '</span> ';
	}

	header += '<span class="name">' + objName + '</span>(';

	argCount = obj.arguments.length;
	for (i in obj.arguments) {
		var arg = obj.arguments[i];

		header += '<span class="type">' + getTypeName(arg.type) + '</span>';

		if ('byReference' in arg) {
			header += '<span class="byReference">&</span>';
		}

		header += ' <span class="name b">' + arg.name + '</span>';

		if ('defaultValue' in arg) {
			header += '<span class="defaultValue"> = ' + arg.defaultValue + '</span>';
		}

		if (i < argCount - 1) {
			header += ', ';
		}
	}

	header += ')';
	header += '</pre>';

	return header;
}

function loadTypedefDetails(name, obj)
{
	var details = '';

	details += '<h1 class="page-header">' + name + ' <span class="kind">Typedef</span>' + '</h1>';

	details += buildTypedefHeader(name, obj);

	details += '<h4 class="sub-header2">Description</h4>';
	details += '<p style="margin-left: 30px;">';
	if ('docText' in obj) {
		details += obj.docText
	} else {
		details += '<span class="text-muted">This typedef has no description.</span>';
	}
	details += '</p>';

	if (obj.tags.length > 0) {
		details += '<h4 class="sub-header2">Tags</h4>';
		details += '<dl style="margin-left: 30px;">';

		for (i in obj.tags) {
			var tag = obj.tags[i];
			details += '<div style="margin-bottom: 20px;">';
			details += '<dt class="mono">';
			details += '<span class="type">' + getTypeName(tag.type) + '</span>';
			details += ' <span class="name">' + tag.name + '</span>';
			details += '</dt>';

			details += '<dd>';
			if ('docText' in tag) {
				details += tag.docText
			} else {
				details += '<i class="text-muted">No description.</i>';
			}
			details += '</dd>';

			details += '</div>';
		}

		details += '</dl>';
	}

	return details
}

function buildTypedefHeader(objName, obj)
{
	var header = '<pre class="syntax mono">';

	header += '<span class="type">typedef</span> <span class="name">' + name + '</span> = function void(';

	tagCount = obj.tags.length;
	for (i in obj.tags) {
		var arg = obj.tags[i];

		header += '<span class="type">' + getTypeName(arg.type) + '</span>';
		header += ' <span class="name b">' + arg.name + '</span>';

		if (i < tagCount - 1) {
			header += ', ';
		}
	}

	header += ')';
	header += '</pre>';

	return header;
}
function loadEnumDetails(name, obj)
{
	var details = '';

	details += '<h1 class="page-header">' + name + ' <span class="kind">Enumeration</span>' + '</h1>';

	details += '<h4 class="sub-header2">Description</h4>';
	details += '<p style="margin-left: 30px;">';
	if ('docText' in obj) {
		details += obj.docText
	} else {
		details += '<i class="text-muted">This enumaration has no description.</i>';
	}
	details += '</p>';

	details += '<h4 class="sub-header2">Values <span class="badge">' + obj.entries.length + '</span></h4>';

	details += '<div class="table-responsive">';
	details += '<table class="table table-bordered table-hover">';
	details += '<thead><tr>';
	details += '<th>Name</th>';
	details += '<th>Description</th>';
	details += '</tr></thead>';

	details += '<tbody>';
	for (entry in obj.entries) {
		details += '<tr>';
		details += '<td class="col-md-2 mono name">' + obj.entries[entry].name + '</td>';

		if ('docText' in obj.entries[entry]) {
			details += '<td><p>' + obj.entries[entry].docText + '</p></td>';
		} else {
			details += '<td><p><i class="text-muted">No description.</i></p></td>';
		}

		details += '</tr>';
	}
	details += '</tbody>';

	details += '</table>';
	details += '</div>';



	return details;
}

function loadConstantDetails(name, obj)
{
	var details = '';

	details += '<h1 class="page-header">' + name + ' <span class="kind">Constant</span>' + '</h1>';

	details += '<pre class="syntax mono">';
	details += '<span class="name">' + name + '</span> = <span class="constantValue">' + obj.value + '</span>';
	details += '</pre>';

	details += '<h4 class="sub-header2">Description</h4>';
	details += '<p style="margin-left: 30px;">';
	if ('docText' in obj) {
		details += obj.docText
	} else {
		details += '<i class="text-muted">This enumaration has no description.</i>'
	}
	details += '</p>';

	return details;
}

function loadMainPage()
{
	var details = '';
	details += '<div class="col-lg-12">';
	details += '<h1 class="page-header">Welcome to the TeamGames Scripting API Reference</h1>';
	details += '<div class="bs-callout">';
	details += '<p>Enter a search term on the left to look for symbols in the TeamGames include files.</p>';
	details += '</div>';
	details += '<div class="bs-callout bs-callout-info">';
	details += '<h4>Looking for more information?</h4>';
	details += '<p>For more information, see the <a href="https://github.com/KissLick/TeamGames/wiki">TeamGames Wiki</a>, which contains some examples and explanations.</p>';
	details += '</div>';
	details += '</div>';

	$('#objectDetail').html(details);
	$('#objects li').removeClass('active');

	var url = location.href;
	var questionMark = url.indexOf('?');

	if (questionMark != -1) {
		url = url.substring(0, questionMark);
		window.history.replaceState({} , document.title, url);
	}

	$(document).prop('title', 'TeamGames Scripting API Reference');
}

function getTypeName(type)
{
	if (type in objects) {
		return '<a class="type" href="#" onclick="loadObjectDetails(\'' + type + '\'); return false;">' + type + '</a>';
	} else {
		return type;
	}
}

function search(name)
{
	name = name.toLowerCase();

	$('#objects li').each(function(index, element){
		var objName = $(this).attr('id');
		var objDesc = '';

		if ('docText' in objects[objName]) {
			objects[objName]['docText'].toLowerCase();
		}

		objName = objName.toLowerCase();

		if (objName.indexOf(name) != -1 || objDesc.indexOf(name) != -1) {
			$(this).show();
		} else {
			$(this).hide();
		}
	});
}

function updateBreadCrumbs(newCrumb)
{
	$('#breadcrumb').html('');
	crumbs.push(newCrumb);

	if (crumbs.length > 7) {
		crumbs.shift();
	}

	var breads = '';
	for (crumb in crumbs) {
		breads += '<li><a href="#" onclick="loadObjectDetails(\'' + crumbs[crumb] + '\'); return false;">' + crumbs[crumb] + '</a></li>';
	}

	$('#breadcrumb').html(breads);

	$('#breadcrumb').css('visibility', 'visible');
}

// ---------------------------

function clearSearch()
{
	$('#search').val('');
	$('#search').focus();
	$('#search-clear').hide();
	$("#objects li").show();
}

function capitalizeFirstLetter(string)
{
	return string.charAt(0).toUpperCase() + string.slice(1);
}