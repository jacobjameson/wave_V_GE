from selenium import webdriver
from bs4 import BeautifulSoup
import json

# Set up the Selenium WebDriver for Safari
driver = webdriver.Safari()

# Base URL for concatenation
base_url = "https://addhealth-navigator.cpc.unc.edu"

# Dictionary to hold all extracted data
all_variable_data = {}

# Function to scrape data for a single variable
def scrape_variable_data(relative_url):
    full_url = base_url + relative_url
    driver.get(full_url)
    soup = BeautifulSoup(driver.page_source, 'html.parser')

    # Extract the variable name
    h3_tags = soup.find_all('h3')
    variable_name = None
    for tag in h3_tags:
        if 'Summary Statistics for' in tag.text:
            variable_name = tag.text.split("'")[1]
            break

    if not variable_name:
        print("Variable name not found for URL:", full_url)
        return None

    # Find the summary statistics table
    table = soup.find('table', id='frequency-table')

    # Extract data from the table
    data = {}
    if table:
        for row in table.find_all('tr')[1:]:
            cells = row.find_all('td')
            if len(cells) >= 3:
                value = cells[0].get('data-value', '').strip()
                label = cells[2].get('data-value', '').strip()
                data[value] = label

    return variable_name, data

# Fetch the main page to get variable URLs
driver.get(base_url + "/item/example.org/fc88a92e-6bae-4753-bb5a-0cb698ba1bc8/7")
soup = BeautifulSoup(driver.page_source, 'html.parser')
container = soup.find('div', class_='multiple-list-container')

# Extract variable names and URLs
variables = []
if container:
    for item in container.find_all('li'):
        a_tag = item.find('a')
        if a_tag:
            variable_name = a_tag.text.strip()
            variable_url = a_tag['href']
            variables.append((variable_name, variable_url))

# Scrape data for each variable (example: first 10 variables)
for item in variables:
    var_name, var_data = scrape_variable_data(item[1])
    if var_name and var_data:
        all_variable_data[var_name] = var_data

# Close the WebDriver
driver.quit()

# Save the data to a JSON file
with open('variable_data.json', 'w') as file:
    json.dump(all_variable_data, file, indent=4)

print("Data scraping complete. Data saved to variable_data.json.")