import { transformUsers } from '../../app/assets/javascripts/utils/model_utils';

describe('transformUsers', () => {
  it('transforms user names correctly', () => {
    const users = [
      { real_name: 'John Doe Smith' },
      { real_name: 'Bob Charles Johnson' },
      { real_name: 'Alice' },
      { real_name: 'Smith Time' },
      { real_name: '' },
    ];

    const transformedUsers = transformUsers(users);

    const expectedTransformedUsers = [
      { real_name: 'John Doe Smith', first_name: 'John', last_name: 'Smith' },
      { real_name: 'Bob Charles Johnson', first_name: 'Bob', last_name: 'Johnson' },
      { real_name: 'Alice', first_name: 'Alice' },
      { real_name: 'Smith Time', first_name: 'Smith', last_name: 'Time' },
      { real_name: '' },
    ];

    expect(transformedUsers).toEqual(expectedTransformedUsers);
  });
});
