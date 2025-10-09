const { URL } = require('url');

function resolveApiBase(req) {
  const cfg = process.env.API_URL || (function () { try { return require('./config').apiUrl; } catch (_) { return null; } })();
  if (cfg) {
    try {
      const u = new URL(cfg);
      // Ensure path ends with /api (without trailing slash)
      let path = u.pathname || '';
      if (!/\/api\/?$/.test(path)) {
        path = (path.replace(/\/$/, '')) + '/api';
      } else {
        path = path.replace(/\/$/, '');
      }
      return `${u.protocol}//${u.host}${path}`;
    } catch (_) {}
  }
  const origin = `${req.protocol}://${req.get('host')}`;
  return `${origin}/api`;
}

function buildProfileImageUrl(profileImage, req) {
  if (!profileImage) return null;
  const s = String(profileImage);
  if (/^https?:\/\//i.test(s) || s.startsWith('data:')) return s;
  // If it's already an absolute path under /api/images or /images
  if (s.startsWith('/api/images/')) {
    const origin = `${req.protocol}://${req.get('host')}`;
    return `${origin}${s}`;
  }
  if (s.startsWith('/images/')) {
    const base = resolveApiBase(req); // .../api
    return `${base}${s}`;
  }
  // Likely a GridFS id
  if (/^[a-fA-F0-9]{24}$/.test(s)) {
    const base = resolveApiBase(req);
    return `${base}/images/${s}`;
  }
  return s; // leave untouched
}

function getOrigin(req) {
  return `${req.protocol}://${req.get('host')}`;
}

function buildInlineUserImageUrl(userId, req) {
  if (!userId) return null;
  const origin = getOrigin(req);
  return `${origin}/api/users/${userId.toString()}/profile-image`;
}

module.exports = { resolveApiBase, buildProfileImageUrl, getOrigin, buildInlineUserImageUrl };
