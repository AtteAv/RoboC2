*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Embeds the screenshot of the robot to the PDF receipt
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             Collections
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get order file
    Open page

    ${table}=    Read table from CSV    orders.csv

    FOR    ${row}    IN    @{table}
        Handle order    ${row}
    END

    Add receipts to archive
    [Teardown]    Close Browser


*** Keywords ***
Get order file
    Add text    Please enter the URL to order file
    Add text    Hint: the correct file: https://robotsparebinindustries.com/orders.csv
    Add text input    name=address    label=Address
    Add submit buttons    buttons=Continue

    ${dialog}=    Show dialog
    ${result}=    Wait dialog    ${dialog}
    Download    ${result.address}

Open page
    ${secret}=    Get Secret    Web-info
    Open Available Browser    ${secret}[Web-address]

Handle order
    [Arguments]    ${row}
    Close modal
    Fill the form    ${row}

    ${orderNum}=    Set Variable    ${row}[Order number]
    Save preview    ${orderNum}
    Submit Order
    Generate receipt pdf    ${orderNum}
    Switch to next order

Close modal
    Click Button    xpath=//div[@class='alert-buttons']//button[@class='btn btn-dark']

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Click Button    id=id-body-${row}[Body]
    Input Text    xpath=//input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id=address    ${row}[Address]

Save preview
    [Arguments]    ${orderNum}
    Click Button    id=preview
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep    0.5s    #Make sure the image has fully loaded
    Screenshot    id=robot-preview-image    ${OUTPUT_DIR}${/}preview${orderNum}.jpg

Submit Order
    Wait Until Keyword Succeeds    5x    0.8s
    ...    Attempt to submit form

Attempt to submit form
    Wait Until Element Is Visible    id:order
    Click Button    id=order
    Wait Until Element Is Visible    id:receipt

Generate receipt pdf
    [Arguments]    ${orderNum}
    ${receipt}=    Get Element Attribute    id=receipt    outerHTML
    HTML To PDF    ${receipt}    ${OUTPUT_DIR}${/}receipt${orderNum}.pdf
    ${image}=    Create List    ${OUTPUT_DIR}${/}preview${orderNum}.jpg
    Add Files To Pdf    ${image}    ${OUTPUT_DIR}${/}receipt${orderNum}.pdf    True

Switch to next order
    Wait Until Element Is Visible    id:order-another
    Click Button    id=order-another

Add receipts to archive
    ${ReceiptDir}=    Set Variable    ${OUTPUT_DIR}${/}Receipts
    ${recList}=    Find Files    */*.pdf    ${OUTPUT_DIR}
    Create Directory    ${ReceiptDir}
    ${directory_not_empty}=    Is Directory Not Empty    ${ReceiptDir}
    IF    ${directory_not_empty}    Empty Directory    ${ReceiptDir}

    Copy Files    ${recList}    ${ReceiptDir}
    Archive Folder With Zip    ${ReceiptDir}    ${OUTPUT_DIR}${/}Receipts.zip
