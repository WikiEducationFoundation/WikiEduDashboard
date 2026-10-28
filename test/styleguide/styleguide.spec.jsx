describe('Styleguide examples', () => {
  const globalKeys = ['I18n', 'i18n', 'Features', 'defaultLocale', 'locale',
    'availableLocales', 'stores', 'IS_REACT_ACT_ENVIRONMENT'];
  let savedGlobals;
  let savedBody;
  let roots;
  let act;
  let Simulate;
  let rootSpy;
  let listenerSpy;

  beforeEach(() => {
    jest.resetModules();
    savedGlobals = globalKeys.map(key => [key, Object.getOwnPropertyDescriptor(window, key)]);
    savedBody = document.body.innerHTML;
    delete window.I18n;
    delete window.i18n;
    ({ act, Simulate } = require('react-dom/test-utils'));
    const client = require('react-dom/client');
    const createRoot = client.createRoot;
    roots = [];
    rootSpy = jest.spyOn(client, 'createRoot').mockImplementation((container) => {
      const root = createRoot(container);
      roots.push(root);
      return root;
    });
    listenerSpy = jest.spyOn(document, 'addEventListener');
    global.Features = { user_signed_in: false };
    global.IS_REACT_ACT_ENVIRONMENT = true;
    document.body.innerHTML = ['date-picker-enabled', 'date-picker-disabled',
      'calendar', 'rich-text', 'popover', 'loading']
      .map(id => `<div id="${id}"></div>`).join('');
  });

  afterEach(() => {
    listenerSpy.mock.calls.forEach(([type, listener, options]) => {
      if (type === 'DOMContentLoaded') document.removeEventListener(type, listener, options);
    });
    act(() => roots.forEach(root => root.unmount()));
    rootSpy.mockRestore();
    listenerSpy.mockRestore();
    document.body.innerHTML = savedBody;
    savedGlobals.forEach(([key, descriptor]) => {
      if (descriptor) Object.defineProperty(window, key, descriptor);
      else delete window[key];
    });
  });

  it('enforces the editable date-picker bounds, including both boundary days', () => {
    global.defaultLocale = 'en';
    global.locale = 'en';
    global.availableLocales = ['en'];
    global.stores = { en: { courses: { loading: 'Loading test translation' } } };

    act(() => {
      require('../../app/assets/javascripts/styleguide/styleguide');
      document.dispatchEvent(new Event('DOMContentLoaded'));
    });

    const dateInput = document.querySelector('#date-picker-enabled input');
    const findDay = day => Array.from(document.querySelectorAll(
      '#date-picker-enabled .DayPicker-Day:not(.DayPicker-Day--outside)'
    )).find(cell => cell.textContent.trim() === String(day));

    act(() => Simulate.click(dateInput));
    expect(findDay(9).getAttribute('aria-disabled')).toBe('true');
    act(() => Simulate.click(findDay(9)));
    expect(dateInput.value).toBe('2016-06-22');

    expect(findDay(10).getAttribute('aria-disabled')).toBe('false');
    act(() => Simulate.click(findDay(10)));
    expect(dateInput.value).toBe('2016-06-10');

    act(() => Simulate.click(dateInput));
    expect(findDay(29).getAttribute('aria-disabled')).toBe('false');
    act(() => Simulate.click(findDay(29)));
    expect(dateInput.value).toBe('2016-06-29');

    act(() => Simulate.click(dateInput));
    expect(findDay(30).getAttribute('aria-disabled')).toBe('true');
    act(() => Simulate.click(findDay(30)));
    expect(dateInput.value).toBe('2016-06-29');

    [
      ['2016-06-09', '2016-06-29'],
      ['2016-06-10', '2016-06-10'],
      ['2016-06-29', '2016-06-29'],
      ['2016-06-30', '2016-06-29']
    ].forEach(([value, expected]) => {
      act(() => Simulate.change(dateInput, { target: { value } }));
      act(() => Simulate.blur(dateInput));
      expect(dateInput.value).toBe(expected);
    });
  });

  it.each([
    ['en', 'Loading test translation'],
    ['es', 'Cargando test translation']
  ])('initializes and exercises standalone examples in %s', (locale, loadingText) => {
    global.defaultLocale = 'en';
    global.locale = locale;
    global.availableLocales = ['en', 'es'];
    global.stores = {
      en: { courses: { loading: 'Loading test translation' } },
      es: { courses: { loading: 'Cargando test translation' } }
    };

    act(() => {
      require('../../app/assets/javascripts/styleguide/styleguide');
      document.dispatchEvent(new Event('DOMContentLoaded'));
    });

    const dateInput = document.querySelector('#date-picker-enabled input');
    expect(dateInput.value).toBe('2016-06-22');
    expect(document.querySelector('#date-picker-disabled').textContent).toContain('2016-06-22');
    expect(document.querySelector('#calendar .DayPicker')).not.toBeNull();
    expect(document.querySelector('#loading').textContent).toBe(loadingText);
    expect(window.i18n.locale).toBe(locale);
    expect(window.i18n.defaultLocale).toBe('en');
    expect(window.i18n.availableLocales).toEqual(['en', 'es']);

    act(() => Simulate.click(dateInput));
    expect(document.querySelector('#date-picker-enabled .DayPicker--visible')).not.toBeNull();
    act(() => Simulate.keyDown(dateInput, { keyCode: 27 }));
    expect(document.querySelector('#date-picker-enabled .DayPicker--visible')).toBeNull();

    const textarea = document.querySelector('#rich-text textarea');
    act(() => Simulate.change(textarea, { target: { value: 'Updated example' } }));
    expect(textarea.value).toBe('Updated example');

    act(() => Simulate.click(document.querySelector('#popover button')));
    expect(document.querySelector('#popover').textContent).toContain('"Rows" content');
    expect(document.querySelector('#popover .pop.open')).not.toBeNull();
    act(() => Simulate.click(document.querySelector('#popover button')));
    expect(document.querySelector('#popover .pop.open')).toBeNull();
  });
});
