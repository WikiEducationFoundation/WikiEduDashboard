// Flatten nested profile data without dropping summary or course fields.
export const profileCsv = (data) => {
  const rows = [['field', 'value']];
  const visit = (value, path) => {
    if (value !== null && typeof value === 'object') {
      Object.entries(value).forEach(([key, child]) => visit(child, path ? `${path}.${key}` : key));
    } else {
      rows.push([path, value ?? '']);
    }
  };
  visit(data, '');
  const escape = (value) => {
    let text = String(value);
    // Spreadsheet programs must treat user-controlled strings as text.
    if (typeof value === 'string' && /^[=+\-@\t\r\n]/.test(text)) text = `'${text}`;
    return `"${text.replace(/"/g, '""')}"`;
  };
  return `\uFEFF${rows.map(row => row.map(escape).join(',')).join('\r\n')}`;
};
