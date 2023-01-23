//This alert component pops up when the user is going through training too fast.

import React from 'react'
import { Button, Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions } from '@mui/material'
import {useState} from 'react'


export default function Alert() {

    const[open, setOpen] = useState(true)

  return (
    <>
    <Dialog open = {open} 
    onClose={()=> setOpen(false)} 
    aria-labelledby='dialog-title'
    aria-describedby='dialog-description'>

        <DialogTitle id='dialog-title'>Please take your time!</DialogTitle>
        <DialogContent>
            <DialogContentText id='dialog-description'>It is very important that you learn the training content thoroughly.</DialogContentText>
        </DialogContent>
        <DialogActions>
            <Button color='success' onClick={()=> setOpen(false)}>Close</Button>
        </DialogActions>       
    </Dialog>
    
    </>
  )
}