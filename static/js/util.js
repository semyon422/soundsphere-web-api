// response.ok 200-299 https://learn.javascript.ru/fetch

// https://learn.javascript.ru/cookie
function get_cookie(name) {
	let matches = document.cookie.match(new RegExp(
		"(?:^|; )" + name.replace(/([\.$?*|{}\(\)\[\]\\\/\+^])/g, '\\$1') + "=([^;]*)"
	));
	return matches ? decodeURIComponent(matches[1]) : undefined;
}

function set_cookie(name, value, options = {}) {
	options = {
		path: '/',
		...options
	};

	if (options.expires instanceof Date) {
		options.expires = options.expires.toUTCString();
	}

	let updatedCookie = encodeURIComponent(name) + "=" + encodeURIComponent(value);

	for (let optionKey in options) {
		updatedCookie += "; " + optionKey;
		let optionValue = options[optionKey];
		if (optionValue !== true) {
			updatedCookie += "=" + optionValue;
		}
	}

	document.cookie = updatedCookie;
}

function delete_cookie(name) {
	set_cookie(name, "", {
		'max-age': -1
	})
}

const encode_get_params = p => "?" + Object.entries(p).map(kv => kv.map(encodeURIComponent).join("=")).join("&");

function toArray(a) {
	return Array.isArray(a) ? a : []
}

function formatDate(time) {
	// return new Date(time * 1e3).toUTCString()
	return new Date(time * 1e3).toLocaleString()
}

async function _get(url, obj) {
	let params = obj ? encode_get_params(obj) : ''
	let response = await fetch(url + params, {
		method: 'GET',
		credentials: 'same-origin'
	})
	let response_json = await response.json()
	return response_json
}

async function _fetch_json(url, body, method) {
	let response
	if (body) {
		response = await fetch(url, {
			method: method,
			body: body,
			headers: { 'Content-Type': 'application/json' },
			credentials: 'same-origin'
		})
	} else {
		response = await fetch(url, {
			method: method,
			credentials: 'same-origin'
		})
	}
	let response_json = await response.json()
	return response_json
}

async function _fetch(url, obj, method) {
	let response
	if (obj) {
		response = await fetch(url, {
			method: method,
			body: JSON.stringify(obj),
			headers: { 'Content-Type': 'application/json' },
			credentials: 'same-origin'
		})
	} else {
		response = await fetch(url, {
			method: method,
			credentials: 'same-origin'
		})
	}
	let response_json = await response.json()
	return response_json
}

async function _post(url, obj) {
	return await _fetch(url, obj, "POST")
}

async function _patch(url, obj) {
	return await _fetch(url, obj, "PATCH")
}

async function _put(url, obj) {
	return await _fetch(url, obj, "PUT")
}

async function _delete(url, obj) {
	return await _fetch(url, obj, "DELETE")
}

// https://stackoverflow.com/a/53593328
function JSONstringifyOrder(obj, space) {
	var allKeys = []
	var seen = {}
	JSON.stringify(obj, (key, value) => {
		if (!(key in seen)) {
			allKeys.push(key)
			seen[key] = null
		}
		return value
	});
	allKeys.sort()
	return JSON.stringify(obj, allKeys, space)
}
