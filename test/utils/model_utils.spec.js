import { transformUsers } from '../../app/assets/javascripts/utils/model_utils';

describe('transformUsers function', () => {
  it('transforms users with real names and maintains sorting order', () => {
    const users = [
      { id: 1, real_name: 'John Doe' },
      { id: 2, real_name: 'Alice Mary Smith' },
      { id: 3, real_name: 'Bob Johnson' },
      { id: 4 },
    ];

    const transformedUsers = transformUsers(users);

    expect(transformedUsers).toEqual([
      { id: 1, real_name: 'John Doe', first_name: 'John', last_name: 'Doe' },
      { id: 2, real_name: 'Alice Mary Smith', first_name: 'Alice', last_name: 'Smith' },
      { id: 3, real_name: 'Bob Johnson', first_name: 'Bob', last_name: 'Johnson' },
      { id: 4 },
    ]);
  });
});
