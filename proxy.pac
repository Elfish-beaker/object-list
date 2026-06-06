// Compatibility helpers for local tester environments.
function __isPlainHostName(host) { return host.indexOf(".") === -1; }
function __dnsDomainIs(host, domain) {
  host = String(host || "").toLowerCase();
  domain = String(domain || "").toLowerCase();
  if (!domain) return false;
  if (domain.charAt(0) !== ".") domain = "." + domain;
  return host.length >= domain.length && host.slice(-domain.length) === domain;
}
function __shExpMatch(str, shexp) {
  str = String(str || "");
  shexp = String(shexp || "").replace(/[.+^${}()|[\]\\]/g, "\\$&");
  shexp = "^" + shexp.replace(/\*/g, ".*").replace(/\?/g, ".") + "$";
  return new RegExp(shexp).test(str);
}
var isPlainHostName = (typeof isPlainHostName === "function") ? isPlainHostName : __isPlainHostName;
var dnsDomainIs = (typeof dnsDomainIs === "function") ? dnsDomainIs : __dnsDomainIs;
var shExpMatch = (typeof shExpMatch === "function") ? shExpMatch : __shExpMatch;
function FindProxyForURL(url, host) {
  host = String(host || "").toLowerCase();
  if (isPlainHostName(host)) { return "DIRECT"; }
  return "PROXY 43.156.175.175:8080; DIRECT";
}
