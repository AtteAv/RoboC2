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


*** Variables ***
${rowCount}
${columnCount}
${currentOrderIndex}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get order file
    Open page

    ${table}=    Read table from CSV    orders.csv
    ${rowCount}    ${columnCount}=    Get Table Dimensions    ${table}

    FOR    ${currentOrderIndex}    IN RANGE    0    ${rowCount}    1
        Handle order    ${currentOrderIndex}
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
    [Arguments]    ${orderCnt}
    Close modal
    Fill the form    ${orderCnt}
    Save preview    ${orderCnt}
    Wait Until Keyword Succeeds    5x    0.8s    Order robot    ${orderCnt}

Close modal
    Click Button    xpath=//div[@class='alert-buttons']//button[@class='btn btn-dark']

Fill the form
    [Arguments]    ${orderCnt}

    ${table}=    Read table from CSV    orders.csv
    ${row}=    Get Table Row    ${table}    ${orderCnt}
    Select From List By Index    head    ${row}[Head]
    Click Button    id=id-body-${row}[Body]
    Input Text    xpath=//input[@min=1]    ${row}[Legs]
    Input Text    id=address    ${row}[Address]

Save preview
    [Arguments]    ${orderCnt}
    Click Button    id=preview
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep    0.5s    #Make sure the image has fully loaded
    Screenshot    id=robot-preview-image    ${OUTPUT_DIR}${/}preview${orderCnt}.jpg

Order robot
    [Arguments]    ${orderCnt}
    Wait Until Element Is Visible    id:order
    Click Button    id=order
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id=receipt    outerHTML
    HTML To PDF    ${receipt}    ${OUTPUT_DIR}${/}receipt${orderCnt}.pdf
    ${image}=    Create List    ${OUTPUT_DIR}${/}preview${orderCnt}.jpg
    Add Files To Pdf    ${image}    ${OUTPUT_DIR}${/}receipt${orderCnt}.pdf    True
    Wait Until Element Is Visible    id:order-another
    Click Button    id=order-another

Add receipts to archive
    ${recList}=    Find Files    **/*.pdf    ${OUTPUT_DIR}
    Create Directory    ${OUTPUT_DIR}${/}Receipts
    Copy Files    ${recList}    ${OUTPUT_DIR}${/}Receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${OUTPUT_DIR}${/}Receipts.zip
