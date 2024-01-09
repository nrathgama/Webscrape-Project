from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import csv
import time
import random
import pandas as pd

# Initialize the driver
driver = webdriver.Chrome()

def random_delay(start=1, end=3):
    # Implements a random delay
    time.sleep(random.uniform(start, end))

# Number of pages to scrape per cycle
PAGES_PER_CYCLE = 1
# Number of pages to scrape in total
TOTAL_PAGES = 200

print('All setup is complete')

# set an error counter to handle if we have run too many pages
error_count = 0

material_urls = [
                    'Steel',
                    'Aluminum',
                    'PVC',
                    'Stainless+Steel',
                    'Lead-Free+PVC',
                    'Copper+Free+Aluminum',
                    'Feraloy+Iron+Alloy',
                    'Non-Metallic',
                    'Galvanized+Steel',
                    'Hot-Dip+Galvanized+Steel',
                    'Iron',
                    'Die+Cast+Alunium',
                    'Polyethylene',
                    'Ferrous+Metal',
                    'Malleable+Iron',
                    'Carbon+Steel',
                    'Electroplated+Steel',
                    'Plastic',
                    'Zinc+Plated+Steel',
                    'Electro+Galvanized+Steel',
                    'PVC-Coated+Galvanized+Steel',
                    'ABS',
                    'Bronze',
                    'Neoprene',
                    'Zinc+Plated',
                    'PVC+Coated',
                    'AAcrylnitril+Butadien+Styrol+%28ABS%29'
                ]

for url_link in material_urls:
    print(f'Now running {url_link}')
    start_page = 0
    error_count = 0
    for start_page in range(0, TOTAL_PAGES, PAGES_PER_CYCLE):
        
        # Scrape pages in the current cycle
        for page_number in range(start_page, start_page + PAGES_PER_CYCLE):
            if error_count > 1:
                break
            print(f"Running {str(page_number)}")
            url = f'https://www.graybar.com/conduit-raceway-and-cable-support/c/conduit-raceway-and-cable-support?q=sort%3Arelevance%3Bgbi_categories.1%3AConduit%2C+Raceway+and+Cable+Support%3Bmaterial%3A{url_link}&page={str(page_number)}'
            driver.get(url)
            random_delay()
            
            # obtain all product links
            try:
                product_elements = WebDriverWait(driver, 10).until(
                        EC.presence_of_all_elements_located((By.CSS_SELECTOR, '.product-listing_product-exp__details-link a'))
                    )
                links = [product.get_attribute('href') for product in product_elements]
                error_count = 0
                print(f'Successfully got links for page #{str(page_number)}')

                try:
                    products = []
                    product_elements = WebDriverWait(driver, 10).until(
                            EC.presence_of_all_elements_located((By.CSS_SELECTOR, '.product-listing_product-exp__details-link a'))
                        )
                    links = [product.get_attribute('href') for product in product_elements]

                    for link in links:
                        #print(f'Starting {link}') # comment out in production--too many print statements
                        driver.get(link)
                        random_delay()

                        # Extract the name, SKU, MFR, Price, product deatils.
                        # Extract the name
                        try:
                            name = driver.find_element(By.CSS_SELECTOR, '.product-details .name').text
                        except:
                            name = None

                         # Extract SKU
                        try:
                            sku = driver.find_element(By.CSS_SELECTOR, '.product-details .sku .code').text
                        except:
                            sku = None

                        # Extract MFR #
                        try:
                            mfr = driver.find_element(By.CSS_SELECTOR, '.product-details .manufacturer .code').text
                        except:
                            mfr = None

                        # Extract price
                        try:
                            price = driver.find_element(By.CSS_SELECTOR, '.product-price .price').text
                        except:
                            price = None

                        # Extract price UoM
                        try:
                            price_uom = driver.find_element(By.CSS_SELECTOR, '.product-price .price_uom').text
                        except:
                            price_uom = None

                        # Get product details from the table
                        product_details = {}
                        try:
                            table_rows = driver.find_elements(By.CSS_SELECTOR, '.product-classifications.storeStatus_list.structure table.customTable tbody tr')
                            for row in table_rows:
                                key = row.find_element(By.CSS_SELECTOR, '.attrib').text
                                value = row.find_element(By.CSS_SELECTOR, 'td:nth-child(2)').text
                                product_details[key] = value
                        except:
                            pass

                        product = {
                            'name': name,
                            'MFR #': mfr,
                            'sku': sku,
                            'price': price, 
                            'price_uom': price_uom, 
                            **product_details
                            }
                        products.append(product)

                    # Writes results to a separate CSV file
                    filename = f'//knesmbsdc001/datascience_dev/KDS_DEV/DATA/DE/GRAYBAR_SCRAPED_MATERIAL_CATALOG/{str(page_number)}_{url_link}.csv'
                    df = pd.DataFrame(products)
                    df.to_csv(filename)
                    print(f'Saved data for material: {url_link}')

                except:
                    print(f'We ran page {str(page_number)} but could not get the links')
            except:
                print(f'There was an error for page #{str(page_number)}')
                error_count += 1
                print(f'This is error #{str(error_count)}')

    # print('We are out of pages to run!')


    
