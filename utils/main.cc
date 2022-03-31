#include <iostream>
#include <colorized.hh>

using namespace std;

int main()
{
  cout << red("string") << "\n"
       << symbol("symbolCC") << "\n"
       << green("string") << "\n"
       << yellow("string") << "\n"
       << blue("string") << "\n"
       << purple("string") << "\n"
       << cyan("string") << "\n";
}