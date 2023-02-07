export const printArticleViewer = () => {
  const printWindow = window.open('', '_blank', '');
  const doc = printWindow.document;

  doc.open();
  const pageHeader = document.createElement('div');
  pageHeader.classList.add('header-print-article-viewer');

  pageHeader.appendChild(document.querySelector('.article-viewer-title').cloneNode(true));
  pageHeader.appendChild(document.querySelector('.user-legend-wrap').cloneNode(true));

  doc.write(pageHeader.outerHTML);
  doc.write(document.querySelector('#article-scrollbox-id').innerHTML);
  doc.body.classList.add('print-article-viewer');

  // copy over the stylesheets
  document.head.querySelectorAll('link, style').forEach((htmlElement) => {
    doc.head.appendChild(htmlElement.cloneNode(true));
  });

  doc.close();
  printWindow.focus();

  // Loading the stylesheets can take a while, so we wait a bit before printing.
  setTimeout(() => {
    printWindow.print();
  }, 500);
};
