identification division.
program-id. ListAttendeesScreen is initial.

environment division.
configuration section.
    special-names.
        crt status is Operation.
        alphabet mixed is " ZzYyXxWwVvUuTtSsRrQqPpOoNnMmLlKkJjIiHhGgFfEeDdCcBbAa".

input-output section.
    file-control.
        select optional AttendeesFile assign to AttendeesFileName
            organization is indexed
            access mode is dynamic
            record key is AuthCode of AttendeeRecord
            file status is AttendeeStatus.

data division.
file section.
    fd AttendeesFile is global.
        copy DD-Attendee replacing Attendee by
            ==AttendeeRecord is global.
            88 EndOfAttendeesFile value high-values==.

working-storage section.
    01 Attendee occurs 200 times.
        02 Name     pic x(25) value spaces.
        02 Email    pic x(40) value spaces.
        02 AuthCode pic x(6) value all "0".

    01 AttendeeStatus   pic x(2).
        88 Successful   value "00".
        88 RecordExists value "22".
        88 NoSuchRecord value "23".

    01 CurrentAttendeeNumber pic 999 value zero.
    01 CurrentRow pic 99 value zero.
    01 FirstRecordToShow pic 999 value 1.
    copy DD-ScreenHeader.
    01 LastRecordToShow pic 999 value 20.
    copy DD-Operation.
    01 PageOffset pic 999 value 1.
    01 RecordCount pic 999.
    01 RecordsPerPage constant as 20.
    01 RecordSelected pic 999.

linkage section.
    01 AttendeesFileName pic x(20) value "attendees.dat".
    01 ForegroundColour pic 9 value 2.
    01 ReturnAuthCode pic x(6) value all "0".

screen section.
    01 HomeScreen background-color 0 foreground-color ForegroundColour highlight.
        03 blank screen.
        03 line 1 column 1 from ScreenHeader reverse-video.
        03 line 2 column 1 value "Num" underline.
        03 line 2 column 6 value "Name" underline.
        03 line 2 column 31 value "Email" underline.
        03 line 2 column 71 value "AuthCode" underline.
        03 line 24 column 1 value "Commands: F1 Home, PgUp/PgDown to scroll, Enter number and press ENTER         " reverse-video.

procedure division using AttendeesFileName, ReturnAuthCode, ForegroundColour.

    set environment 'COB_SCREEN_EXCEPTIONS' to 'Y'
    set environment 'COB_SCREEN_ESC' to 'Y'

    initialize ReturnAuthCode
    move zero to RecordCount
    move zeroes to AuthCode of AttendeeRecord
    start AttendeesFile key is greater than AuthCode of AttendeeRecord
    open input AttendeesFile
        read AttendeesFile next record
            at end set EndOfAttendeesFile to true
        end-read
        perform until EndOfAttendeesFile
            add 1 to RecordCount
            move Name of AttendeeRecord to Name of Attendee(RecordCount)
            move Email of AttendeeRecord to Email of Attendee(RecordCount)
            move AuthCode of AttendeeRecord to AuthCode of Attendee(RecordCount)
            read AttendeesFile next record
                at end set EndOfAttendeesFile to true
            end-read
        end-perform
    close AttendeesFile

    sort Attendee
        on descending key Name of Attendee
        collating sequence is mixed

    move zero to PageOffset
    perform until OperationIsBack or OperationIsFinish
        display HomeScreen
        add 1 to PageOffset giving FirstRecordToShow
        move 3 to CurrentRow
        add PageOffset to RecordsPerPage giving LastRecordToShow
        perform varying CurrentAttendeeNumber from FirstRecordToShow by 1
            until CurrentAttendeeNumber greater than LastRecordToShow or
                CurrentAttendeeNumber greater than RecordCount
            display CurrentAttendeeNumber
                at line CurrentRow
                foreground-color ForegroundColour
            end-display
            display Attendee(CurrentAttendeeNumber)
                at line CurrentRow
                column 6
                foreground-color ForegroundColour
            end-display
            add 1 to CurrentRow
        end-perform
        accept RecordSelected at line 24 column 78 foreground-color ForegroundColour
        evaluate true also true
            when OperationIsNextPage also LastRecordToShow is less than RecordCount
                add RecordsPerPage to PageOffset
            when OperationIsPrevPage also PageOffset is greater than or equal to RecordsPerPage
                subtract RecordsPerPage from PageOffset
        end-evaluate
    end-perform

    if OperationIsFinish and RecordSelected greater than zero then
        move AuthCode of Attendee(RecordSelected) to ReturnAuthCode
    end-if

    goback.

end program ListAttendeesScreen.
