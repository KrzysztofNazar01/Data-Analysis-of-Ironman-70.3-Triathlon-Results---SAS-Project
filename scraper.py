from selenium import webdriver
import pandas as pd
import time
from selenium.webdriver.common.by import By


def get_ironman_results(year, link):
    driver = webdriver.Chrome()

    # Load the website in the new tab
    driver.get(link)  # 2017 results

    time.sleep(3)

    # Find the table element on the page
    table = driver.find_element(By.XPATH, '//*[@id="imraceresultstable"]')

    # Get the table HTML
    table_html = table.get_attribute('outerHTML')

    # Use Pandas to read the HTML and create a DataFrame
    df = pd.read_html(table_html)[0]

    # Add leading zeros to the time values
    df['Colon Count'] = df['Swim Time'].str.count(':')
    df.loc[df['Colon Count'] < 2, 'Swim Time'] = df.loc[df['Colon Count'] < 2, 'Swim Time'].apply(lambda x: '0:' + x)
    df = df.drop('Colon Count', axis=1)

    df['Division'] = '"' + df['Division'] + '"'

    df.to_csv('Ironman_results_{}.csv'.format(year), index_label=False, index=False)

    # Close the browser
    driver.quit()


if __name__ == "__main__":
    years = [2017, 2018, 2019]
    links = ['https://www.coachcox.co.uk/imstats/race/467/results/',
             'https://www.coachcox.co.uk/imstats/race/466/results/',
             'https://www.coachcox.co.uk/imstats/race/617/results/']

    data = {'Year': years, 'Link': links}
    df = pd.DataFrame(data)

    for index, row in df.iterrows():
        year = row['Year']
        link = row['Link']
        get_ironman_results(year, link)



