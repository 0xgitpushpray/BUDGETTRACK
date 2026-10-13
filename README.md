# Daybook budget tracker

Daybook is a small, private budget tracker that runs in your browser.

## Get started

On Windows, double-click `start.bat`. Daybook will start on `http://127.0.0.1:3000` and open in your browser. Keep the terminal window open while using the app; press Ctrl+C to stop the local server. You can also run `.\start.ps1` from PowerShell.

If port 3000 is already in use, stop the other process or choose another port by setting `$env:PORT=3001` before running `.\start.ps1`.

Choose a month, set its budget, and add everyday expenses with a description, amount, date, and category. The weekly budget section lets you choose an ISO week (Monday through Sunday), set a separate budget for it, and track spending across that whole week, including weeks that cross months. Use the currency menu to change how amounts are displayed.

Your expenses, monthly budgets, and weekly budgets are saved in the browser on this device. The local server only serves the app files and does not receive or store your budget data. Use **Export Excel** to download the selected month as `daybook-YYYY-MM.xlsx`; each workbook includes an overview and a transaction list. Export each month you want to keep as an Excel file.

Because data is stored in this browser, it is not automatically backed up or shared with other devices. Export your monthly workbooks to keep a separate copy.
