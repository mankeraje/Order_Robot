*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    1s
${order_num}


*** Keywords ***
Get the URL from vault and Open the robot order website
    ${url}=    Get Secret    urls
    Log        ${url}
    Open Available Browser      ${url}[web_url]
	
	
*** Keywords ***
Get the .csv URL from User
    Create Form    Orders.csv URL
    Add Text Input    URL    url
    &{response}    Request Response
    [Return]    ${response["url"]}
        

*** Keywords ***
Get robot orders
    ${CSV_FILE_URL}=    Get the .csv URL from User
    Download        ${CSV_FILE_URL}           overwrite=True
    ${table}=       Read Table From Csv       orders.csv      dialect=excel  header=True
    FOR     ${row}  IN  @{table}
        Log     ${row}
    END
    [Return]    ${table}


*** Keywords ***
Close popup
    Click Button When Visible    //button[@class="btn btn-dark"]

*** Keywords ***
Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview


*** Keywords ***   
Submit the Robot order And check till Success
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion


*** Keywords ***
Submit the robot order
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Submit the Robot order And check till Success


*** Keywords ***
Go to order another robot
    Click Button    order-another
    

*** Keywords ***   
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts   ${CURDIR}${/}output${/}receipt.zip


*** Keywords ***
Fill the form
    [Arguments]    ${localrow}
    ${head}=    Convert To Integer    ${localrow}[Head]
    ${body}=    Convert To Integer    ${localrow}[Body]
    ${legs}=    Convert To Integer    ${localrow}[Legs]
    ${address}=    Convert To String    ${localrow}[Address]
    Select From List By Value   id:head   ${head}
    Click Element   id-body-${body}
    Input Text      id:address    ${address}
    Input Text      xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs}


*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_num}
    Wait Until Element Is Visible    id:order-completion
    ${order_num}=    Get Text    xpath://div[@id="receipt"]/p[1]
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_num}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_num}.pdf    


*** Keywords *** 
Take a screenshot of generated robot image
    [Arguments]    ${order_num}
    Screenshot     id:robot-preview    ${CURDIR}${/}output${/}${order_num}.png
    [Return]       ${CURDIR}${/}output${/}${order_num}.png


*** Keywords ***
Embed the robot screenshots to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}
    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get the URL from vault and Open the robot order website
    ${orders}=    Get robot orders
    FOR    ${row}    IN    @{orders}
        Close popup
        Fill the form    ${row}
        Preview the robot
        Submit the robot order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of generated robot image    ${row}[Order number]
        Embed the robot screenshots to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close All Browsers
