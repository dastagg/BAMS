identification division.
program-id. ImportAttendees.

environment division.
input-output section.
file-control.
    select CSVSourceFile assign to CSVSourceFileName
        organization is line sequential.

    select optional AttendeesFile assign to AttendeesFileName
        organization is line sequential.

data division.
file section.
fd CSVSourceFile.
    01 CSVFileInputLine pic x(255).
        88 EndOfCSVFile value high-values.

fd AttendeesFile is global.
    copy Attendee replacing Attendee by
        ==AttendeeRecord is global.
        88 EndOfAttendeesFile value high-values==.

working-storage section.
    01 CountOfLinesProcessed pic 999 value zero.
    copy Attendee.

    01 TempAttendeeData.
        02 PaidDateFromWeb pic x(10).
        02 ArrivalDayFromWeb pic x(10).
        02 DietFromWeb pic x(20).
        02 StayingLateFromWeb pic x(5).

    01 AttendeesFileName pic x(20) value spaces.
    01 CSVSourceFileName pic x(30) value spaces.
    01 CommandLineArgumentCount pic 9 value zero.

    01 RecordWriteStatus   pic x(2).
        88 Successful   value "00".
        88 RecordExists value "22".
        88 NoSuchRecord value "23".

procedure division.
    accept CommandLineArgumentCount from argument-number
    if CommandLineArgumentCount equal to 2 then
        accept CSVSourceFileName from argument-value
        accept AttendeesFileName from argument-value
    else
        move "barncamp-attendees.csv" to CSVSourceFileName
        move "attendees-seq.dat" to AttendeesFileName
    end-if
    display "Reading from " function trim(CSVSourceFileName) " and writing to " function trim(AttendeesFileName)
    open input CSVSourceFile
    open output AttendeesFile
    read CSVSourceFile
        at end set EndOfCSVFile to true
    end-read
    perform until EndOfCSVFile
        initialize Attendee
        unstring CSVFileInputLine
            delimited by ","
            into
            Name of Attendee,
            Email of Attendee,
            AuthCode of Attendee,
            AmountToPay of Attendee,
            AmountPaid of Attendee,
            PaidDateFromWeb,
            Telephone of Attendee,
            ArrivalDayFromWeb,
            DietFromWeb,
            StayingLateFromWeb,
            NumberOfKids of Attendee
        end-unstring
        if Name of Attendee not equal to 'Name' then
            add 1 to CountOfLinesProcessed
            display "Importing record with authcode of " AuthCode of Attendee
            move ArrivalDayFromWeb(1:3) to ArrivalDay of Attendee
            if PaidDateFromWeb is not equal to spaces then
                move PaidDateFromWeb(1:2) to CentuaryPaid of Attendee
                move PaidDateFromWeb(3:2) to YearPaid of Attendee
                move PaidDateFromWeb(6:2) to MonthPaid of Attendee
                move PaidDateFromWeb(9:2) to DayPaid of Attendee
            end-if
            evaluate AmountPaid of Attendee
                when greater than zero set AttendeePaid of Attendee to true
                when less than or equal to zero set AttendeeNotPaid of Attendee to true
            end-evaluate
            if NumberOfKids of Attendee is less than zero or greater than 5 then
                move zero to NumberOfKids of Attendee
            end-if
            set AttendeeComing of Attendee to true
            move Attendee to AttendeeRecord
            write AttendeeRecord
        end-if
        read CSVSourceFile
            at end set EndOfCSVFile to true
        end-read
    end-perform
    close AttendeesFile
    close CSVSourceFile
    display "Total attendees processed is " CountOfLinesProcessed
stop run
.

end program ImportAttendees.
