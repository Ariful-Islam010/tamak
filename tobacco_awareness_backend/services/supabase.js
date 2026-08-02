const config = require('../config');

/**
 * Central Supabase HTTP helper used by all routers.
 */
async function supabaseReq(method, path, { token = null, jsonData = null, params = null, useServiceRole = false, prefer = null } = {}) {
  let url = `${config.SUPABASE_URL}${path}`;

  if (params) {
    const searchParams = new URLSearchParams(params);
    url += (url.includes('?') ? '&' : '?') + searchParams.toString();
  }

  const key = (useServiceRole && config.SUPABASE_SERVICE_ROLE_KEY) ? config.SUPABASE_SERVICE_ROLE_KEY : config.SUPABASE_ANON_KEY;

  const headers = {
    'apikey': key,
    'Content-Type': 'application/json',
  };

  if (useServiceRole && config.SUPABASE_SERVICE_ROLE_KEY) {
    headers['Authorization'] = `Bearer ${config.SUPABASE_SERVICE_ROLE_KEY}`;
  } else if (token) {
    headers['Authorization'] = token.startsWith('Bearer ') ? token : `Bearer ${token}`;
  } else {
    headers['Authorization'] = `Bearer ${key}`;
  }

  if (prefer) {
    headers['Prefer'] = prefer;
  } else if (['POST', 'PATCH', 'PUT', 'DELETE'].includes(method.toUpperCase())) {
    headers['Prefer'] = 'return=representation';
  }

  const options = {
    method: method.toUpperCase(),
    headers,
  };

  if (jsonData && ['POST', 'PATCH', 'PUT'].includes(method.toUpperCase())) {
    options.body = JSON.stringify(jsonData);
  }

  try {
    const response = await fetch(url, options);
    const text = await response.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }

    return {
      status: response.status,
      ok: response.ok,
      data,
      text,
    };
  } catch (error) {
    console.error('Supabase request error:', error);
    throw new Error(`Supabase request failed: ${error.message}`);
  }
}

module.exports = { supabaseReq };
