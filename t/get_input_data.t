use Test::More qw/no_plan/;

use Data::FormValidator;

{
    my $results = Data::FormValidator->check({},{});
    is_deeply($results->get_input_data, {}, 'get_input_data works for empty hashref' ); 
}

use CGI;
my $q = CGI->new( { key => 'value' });
my $results = Data::FormValidator->check($q,{});

is_deeply($results->get_input_data, $q, 'get_input_data works for CGI object' ); 

{
    my $href = $results->get_input_data(as_hashref => 1);
    is_deeply($href , { key => 'value' },  'get_input_data( as_hashref => 1 ) works for CGI object' ); 
}



