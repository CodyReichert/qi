;;; -*- Mode: LISP; Syntax: Common-lisp; Package: ccl; Base: 10 -*-
;******************************************************************
;*                                                                *
;*    PROGRAM      E V A L   A P P L E     S C R I P T            *
;*                                                                *
;******************************************************************
;* Author       : Alexander Repenning                             *
;* Copyright    : 2003 (c) AgentSheets Inc.                       *
;*                http://www.agentsheets.com                      *
;* Filename     : eval-apple-script.lisp                          *
;* Last Update  : 03/01/05                                        *
;* Version                                                        *
;*    1.0       : 11/05/03                                        *
;*    1.1       : 02/11/04 finder-file-comment                    *
;*    1.1.1     : 03/01/05 export i-chat-.. functions             *
;* HW/SW        : G4, OS X 10.3.8, MCL 5                          *
;* Abstract     : Run Apple Scripts                               *
;*                                                                *
;******************************************************************

(in-package :ccl)

(export '(eval-apple-script i-chat-send-message i-chat-set-status-message
          *applescript-host* do-shell-script))

(require "appleevent-toolkit")



(defun EVAL-APPLE-SCRIPT (Script) "
  in:  Script string;
  out: Result string, Error nil or errorCode;
  Compile and run an AppleScript."
  ;; Peter Desain <Desain@nici.kun.nl>
  (let ((Gscriptingcomponent
	(#_OpenDefaultComponent #$kOSAComponentType #$kOSAGenericScriptingComponentSubtype)))
    (with-aedescs (source result err-mess)
      (%stack-block ((ptr (1+ (length script))))
        (%put-cstring ptr script)
        (ae-error (#_aecreatedesc #$typechar ptr (length script) source))
        (let ((Myoserror
               (#_OSADoScript gScriptingComponent
                source
                #$kOSANullScript
                #$typeChar
                (logior #$kOSAModeNull #$kOSAModeDisplayForHumans)
                result)))
          (case myOSError
            (#.#$noErr  ;; no error: extract result 
             (values
              (let ((Datahandle (rref result :aedesc.datahandle)))
                (with-dereferenced-handles ((ptr1 datahandle))
                  (%str-from-ptr-in-script ptr1 (#_GetHandleSize datahandle))))
              nil))
            (t  ;; error: return error message
             (values
              (progn
                (#_OSAScriptError gScriptingComponent #$kOSAErrorMessage #$typeChar err-mess)
                (format nil "AppleScript error: ~A, code: ~A" 
                        (let ((Datahandle (rref err-mess :aedesc.datahandle)))
                          (with-dereferenced-handles ((ptr1 datahandle))
                            (%str-from-ptr-in-script ptr1 (#_GetHandleSize datahandle)))) 
                        myOSError))
              myOSError))))))))

;_______________________________
; iChat AppleScripts            |
;_______________________________

(defun I-CHAT-SET-STATUS-MESSAGE (String)
  (eval-apple-script
   (format nil "tell application \"iChat\" to set status message to \"~A\"" String)))


(defun I-CHAT-SEND-MESSAGE (Message Receiver)
    (eval-apple-script
   (format nil 
"tell application \"iChat\"
	repeat with a in (first account where id is \"~A\")
		send \"~A\" to a
	end repeat
end tell"
   Receiver Message)))


;_______________________________
; Finder AppleScripts          |
;_______________________________

(defun FINDER-FILE-COMMENT (Pathname) "
  in:  Pathname pathname;
  out: Comment string, error code;
  Get the comment string from the Finder Get Info panel."
  (eval-apple-script
   (format nil
"tell application \"Finder\"
  get comment of file \"~A\"
 end tell"
  (mac-namestring Pathname))))


;;; ---------------------------------------------------------------------------
;;; simple shell script support
;;; ---------------------------------------------------------------------------

(defvar *applescript-host* "System Events")

(defun do-shell-script (script) 
  (let ((command (format nil
                         "tell application \"~A\" ~
                          ~%do shell script \"~A\" ~
                          ~%end tell" 
                         *applescript-host* script)))
    (eval-apple-script command)))
 
#+Test
(do-shell-script "cd ~/documents; ls")


#| Examples:

(dotimes (i 10)
  (i-chat-set-status-message ";-)")
  (sleep 1.0)
  (i-chat-set-status-message ":-)")
  (sleep 1.0)
  (i-chat-set-status-message ":-D")
  (sleep 1.0))

(i-chat-send-message "ciao bello" "AIM:mrvetro")

;; low level


(eval-apple-script "1 / 0")

(eval-apple-script "tell application \"Script Editor\" to activate")

(eval-apple-script "tell application \"iChat\" to activate")

(eval-apple-script "tell application \"iChat\" to set status message to \";-)\"")


(eval-apple-script 
 "property message : \"get a live you old bastard\"

tell application \"iChat\"
	repeat with a in (first account where id is \"AIM:mrvetro\")
		send message to a
	end repeat
end tell")


(finder-file-comment (choose-file-dialog))



(eval-apple-script
"tell application \"Finder\"
	tell item \"Ristretto to Go\"
		tell item \"The Matrix.jpg\"
			get the comment
		end tell
	end tell
end tell")


(eval-apple-script
"tell application \"Finder\"
	tell item \"Ristretto to Go:The Matrix.jpg\"
			get the comment
	end tell
end tell")


(eval-apple-script
"tell application \"Finder\" 
get the comment of file \"Ristretto to Go:The Matrix.jpg\" 
end tell")

;; how to set image: http://www.blankreb.com/studiosnips.php?ID=30




|#

