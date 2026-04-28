require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const email = process.argv[2];

if (!email) {
  console.error('Please provide an email address: node make_admin.js user@example.com');
  process.exit(1);
}

async function promoteToAdmin() {
  console.log(`Attempting to promote ${email} to admin...`);

  // 1. Check if user exists
  const { data: user, error: fetchError } = await supabase
    .from('users')
    .select('*')
    .eq('email', email)
    .single();

  if (fetchError || !user) {
    console.error('Error: User not found in database. Have you logged in to the mobile app with this account yet?');
    console.log('Trying to insert user record instead...');
    
    // Attempt to insert if UID is known (but we don't have it easily here)
    // So we'll stop here and ask them to log in to the app first.
    return;
  }

  // 2. Update role
  const { error: updateError } = await supabase
    .from('users')
    .update({ role: 'admin' })
    .eq('email', email);

  if (updateError) {
    console.error('Failed to update role:', updateError.message);
  } else {
    console.log(`✓ SUCCESS: ${email} is now an ADMIN.`);
    console.log('You can now refresh the Admin Console at http://localhost:3000/admin');
  }
}

promoteToAdmin();
