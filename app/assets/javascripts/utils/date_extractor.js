class ExtractDate {
    /**
     * Class to extract a meeting date from a specified date format.
     * 
     * Date format expected: "Day (MM/DD)" where MM is the month and DD is the day.
     *
     * @param {string} date - The input date string from which to extract the date.
     */
    constructor(date) {
        this.date = date; 
    }

    /**
     * Extracts the date in MM/DD format from the stored date string.
     * 
     * The method uses a regular expression to find the date within parentheses.
     * The expected format is (MM/DD), with possible whitespace around the date.
     * 
     * @returns {string|null} - Returns the extracted date in MM/DD format (without parentheses) if found,
     *                          or null if no valid date is present.
     */
    getDate() {
        // Use a regular expression to match the date format (MM/DD).
        // The regex breakdown:
        // - `\(`: Matches the literal opening parenthesis '('.
        // - `\s*`: Matches any whitespace characters (spaces or tabs) zero or more times.
        // - `(\d{1,2}\/\d{1,2})`: Capturing group that matches:
        //   - `\d{1,2}`: Exactly one or two digits (for MM).
        //   - `\/`: Matches the literal '/' character.
        //   - `\d{1,2}`: Exactly one or two digits (for DD).
        // - `\s*`: Matches any whitespace characters zero or more times.
        // - `\)`: Matches the literal closing parenthesis ')'.
        const match = this.date.trim().match(/\(\s*(\d{1,2}\/\d{1,2})\s*\)/);
        
        // Check if a match was found and return the first capturing group (MM/DD).
        // If no match is found, return null.
        return match && match[1] ? match[1] : null;
    }
}

export default ExtractDate;
