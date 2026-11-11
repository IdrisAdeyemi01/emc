/**
 * EMC Portal backend: a read-only JSON proxy over the "Teachers' Contacts" tab.
 *
 * Contract v1 (CLAUDE.md section 2.7):
 *   GET <web app URL>?action=contacts&key=<EMC_API_KEY>
 *   200 -> { ok: true, fetchedAt, sheet, headers: [...], rows: [[...], ...] }
 *   200 -> { ok: false, error: "unauthorized" | "sheet_not_found"
 *                             | "unknown_action" | "not_configured" | "not_bound"
 *                             | "internal" }
 *
 * Apps Script web apps can't set HTTP status codes, so errors are in the body.
 * Values come from getDisplayValues(), exactly as shown in the sheet ("4:00 PM").
 * All parsing and rules live in Dart (emc_core). No caching: freshness wins.
 *
 * Privacy: never log phone numbers or row contents.
 */

var SHEET_NAME = "Teachers' Contacts";

function doGet(e) {
  try {
    var params = (e && e.parameter) || {};
    var expectedKey = PropertiesService.getScriptProperties().getProperty('EMC_API_KEY');
    if (!expectedKey) {
      console.error('EMC_API_KEY is not set in Script Properties.');
      return json_({ ok: false, error: 'not_configured' });
    }
    if (!params.key || params.key !== expectedKey) {
      return json_({ ok: false, error: 'unauthorized' });
    }
    if (params.action !== 'contacts') {
      return json_({ ok: false, error: 'unknown_action' });
    }
    return json_(readContacts_());
  } catch (err) {
    console.error('doGet failed: ' + (err && err.message));
    return json_({ ok: false, error: 'internal' });
  }
}

/** Reads the whole tab as displayed text: header row + data rows. */
function readContacts_() {
  var spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  if (!spreadsheet) {
    // Only bound scripts (Extensions -> Apps Script from the sheet) have one.
    console.error('Not bound to a spreadsheet. Create the script from the sheet.');
    return { ok: false, error: 'not_bound' };
  }
  var sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (!sheet) {
    return { ok: false, error: 'sheet_not_found' };
  }
  var values = sheet.getDataRange().getDisplayValues();
  return {
    ok: true,
    fetchedAt: new Date().toISOString(),
    sheet: SHEET_NAME,
    headers: values.length > 0 ? values[0] : [],
    rows: values.slice(1),
  };
}

function json_(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload)).setMimeType(
    ContentService.MimeType.JSON
  );
}

/**
 * Run this once from the editor (Run > testContacts) to grant access and
 * check the tab is readable. Logs only the header names and row count.
 */
function testContacts() {
  var result = readContacts_();
  if (!result.ok) {
    console.log('Problem: ' + result.error);
    return;
  }
  console.log('Headers: ' + result.headers.join(' | '));
  console.log('Data rows: ' + result.rows.length);
  var hasKey = !!PropertiesService.getScriptProperties().getProperty('EMC_API_KEY');
  console.log('EMC_API_KEY set: ' + (hasKey ? 'yes' : 'NO, add it in Project Settings'));
}
