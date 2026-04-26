const express = require('express');
const router = express.Router();
const supabase = require('../utils/supabase');

// Get timetable for enrollment
router.get('/:enrollment', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('cms_timetable')
      .select('*')
      .eq('enrollment', req.params.enrollment);

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Save timetable
router.post('/', async (req, res) => {
  try {
    const { enrollment, timetable } = req.body;
    
    // 1. Delete old timetable
    await supabase
      .from('cms_timetable')
      .delete()
      .eq('enrollment', enrollment);

    // 2. Insert new timetable with quoted column mapping
    const entries = timetable.map(entry => ({
      "enrollment": enrollment,
      "courseCode": entry.courseCode,
      "courseTitle": entry.courseTitle,
      "day": entry.day,
      "timeFrom": entry.timeFrom,
      "timeTo": entry.timeTo,
      "roomName": entry.roomName,
      "buildingName": entry.buildingName
    }));

    const { data, error } = await supabase
      .from('cms_timetable')
      .insert(entries)
      .select();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
