*** Settings ***
Documentation       Robot to enter the receipt.
Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.FileSystem
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault


*** Keywords ***
Open The Intranet Website
    ${store_url}=   Get Secret    urls
    Open Available Browser      ${store_url}[storeurl]

*** Keywords ***
Close Modal
        Wait Until Page Contains Element        class:modal
        Click Button        Yep

*** Keywords ***
Fill The Form
    [Arguments]     ${order}
    Select From List By Value      head         ${order}[Head]
    Click Element       //label[./input[@id="id-body-${order}[Body]"]]
    Input Text      //form/div[3]/input     ${order}[Legs]
    Input Text      address     ${order}[Address]
    Click Button        preview
    Collect The Results
    Wait Until Keyword Succeeds     10x      3s      Assert order submitted

*** Keywords ***
Collect File Url
    Add text input    file      label=File Url
    ${response}=    Run dialog
    [Return]    ${response.file}

*** Keywords ***
Download The csv file
    [Arguments]     ${file_url}
    Download    ${file_url}  overwrite=True

*** Keywords ***
Collect The Results
    Wait Until Element Is Visible       robot-preview-image
    Screenshot    robot-preview-image     ${CURDIR}${/}output${/}temp.png     

*** Keywords ***
Export Order Summary As A PDF
    [Arguments]     ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_summary_html}=      Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_summary_html}<img src='${CURDIR}${/}output${/}temp.png' width='480'/>       ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    #${files}=       Create List     ${CURDIR}${/}output${/}temp.png
    #Add Files To Pdf    ${files}     ${CURDIR}${/}output${/}${order_number}.pdf

*** Keywords ***
Assert order submitted
    Click Button    order
    Wait Until Page Contains Element   receipt

*** Keywords ***
Fill The Form Using The Data From The csv File
    ${orders}=       Read table from Csv    orders.csv       header=True
    FOR     ${order}   IN      @{orders}
        Close Modal
        Fill The Form    ${order}
        Export Order Summary As A PDF    ${order}[Order number]
        Click Button    order-another
    END

*** Keywords ***
Zip the receipts
    Archive Folder With Zip     ${CURDIR}${/}output/${/}receipts        ${CURDIR}${/}output${/}receipts.zip

*** Tasks ***
Insert the receipt data and export it as a PDF
    Open The Intranet Website
    ${file}=    Collect File Url
    Download The csv file       ${file}
    Fill The Form Using The Data From The csv File
    Zip the receipts
    [Teardown]      Close Browser
