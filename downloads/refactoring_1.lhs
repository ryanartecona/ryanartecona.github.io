Recently, my team at work read the first few chapters of [*Refactoring: Ruby Edition*](http://www.amazon.com/Refactoring-Edition-Addison-Wesley-Professional-Series/dp/0321984137), a 2009 translation by Jay Fields and Shane Harvie of Martin Fowler's [*Refactoring*](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) from 1999.

The book's first chapter takes the reader through a refactoring of a small example program, with incremental code changes and their motivations explained along the way. The chapter is presumably meant to give the reader a taste of what the authors consider a well-managed refactoring session.

Of the chapters we read, except for a handful of points, I don't have a strong positive or negative opinion on the authors' arguments and insights, (given the book's context). The dominant frustration I *did* have while reading the chapters was from the staggering proportion of considerations that would have been obviated by an expressive static type system.

Naturally, I translated the refactoring session from Chapter 1 into Haskell.

There are significant differences from the Ruby examples and this Haskell translation. In translating, I tried to be faithful to (my reading of) the spirit of the Ruby examples by writing code that might have been written by a junior dev, hammered out in haste, or hacked together without intention of 'making it to production': it fulfills its stated purpose and nothing more. The point is this is straightforward Haskell code, and its differences from the Ruby examples are attributable to differences between the respective languages.

<small>This is a working literate Haskell program, which you can [download here](/downloads/refactoring_1.lhs). You can load it in `ghci` with `:load refactoring_1.lhs`, and inspect any value defined here. If you need to install Haskell first, follow [this guide](https://github.com/bitemyapp/learnhaskell/blob/master/install.md).</small>

--------------------------------------------------------------------------------

First, some basic imports.

> module Refactoring where
> import Data.List (intercalate)

The Starting Point
------------------

The stated purpose of the example program is "to calculate and print a statement of a customer's charges at a video store."

First a Ruby snippet, followed by its Haskell translation.

``` ruby
class Movie
  REGULAR = 0
  NEW_RELEASE = 1
  CHILDRENS = 2

  attr_reader :title
  attr_accessor :price_code

  def initialize(title, price_code)
    @title, @price_code = title, price_code
  end
end
```

> data MovieType = Regular | NewRelease | Childrens
> data Movie = Movie {title :: String, priceCode :: MovieType}

The movie price codes were defined as integer constants in Ruby, but their purpose was to be discriminated in a `case` statement as though they together formed an enum. Ruby doesn't have enums, but Haskell does, as a simple use case of an [algebraic data type](https://wiki.haskell.org/Algebraic_data_type).

Haskell doesn't have classes, so our `Movie` is just a data type. This does nothing more than introduce the `Movie` type along with its only constructor, also named `Movie`, and the record of the two fields it represents.

```ruby
class Rental
  attr_reader :movie, :days_rented
  def initialize(movie, days_rented)
    @movie, @days_rented = movie, days_rented
  end
end
```

> type DaysRented = Int
> data Rental = Rental {movie :: Movie, daysRented :: DaysRented}

Our `Rental` type and constructor here work the same as `Movie` above. We give an alias to the `Int` type called `DaysRented` so that we can keep track of what that `Int` is supposed to represent. To be clear, this gets us no more type safety than using `Int` directly (the type system treats them as interchangeable), but it helps our type signatures better document programmer intent.

```ruby
class Customer
  attr_reader :name
  def initialize(name)
    @name = name
    @rentals = []
  end
  def add_rental(arg)
    @rentals << arg
  end
```

> data Customer = Customer {name :: String, rentals :: [Rental]}
>
> addRental :: Customer -> Rental -> Customer
> addRental cust rental = cust {rentals = rental : rentals cust}

This `Customer` type and constructor should look familiar. The `addRental` function creates a new Customer with the `name` and `rentals` of the given `Customer`, except with an additional rental pushed onto the front of the list with the `:` operator (pronounced 'cons'). The `cust {rentals = ...}` bit is called _record update syntax_, and it's how you create a new record by updating the field of an existing record. Unmentioned fields like `name` get passed through unchanged.

```ruby
# inside Customer class
  def statement
    total_amount, frequent_renter_points = 0, 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      this_amount = 0

      # determine amounts for each line
      case element.movie.price_code
      when Movie::REGULAR
        this_amount += 2
        this_amount += (element.days_rented - 2) * 1.5 if element.days_rented > 2
      when Movie::NEW_RELEASE
        this_amount += element.days_rented * 3
      when Movie::CHILDRENS
        this_amount += 1.5
        this_amount += (element.days_rented - 3) * 1.5 if element.days_rented > 3
      end

      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      if element.movie.price_code == Movie.NEW_RELEASE && element.days_rented > 1
          frequent_renter_points += 1
      end

      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
      total_amount += this_amount
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points" result
  end
end
```

> statement :: Customer -> String
> statement c = unlines
>     [ "Rental record for " ++ name c
>     , intercalate "\n" rentalReportLines
>     , "Amount owed is " ++ show totalAmount
>     , "You earned " ++ show totalFrequentRenterPoints ++ " frequent renter points"
>     ]
>   where
>   (rentalReportLines, totalAmount, totalFrequentRenterPoints) = foldl f ([], 0, 0) (rentals c)
>
>   f :: ([String], Double, Int) -> Rental -> ([String], Double, Int)
>   f (result, accAmount, accFRPts) rental =
>     let chrg = charge rental
>         pts = frequentRenterPoints rental
>         rentalReportLine = "\t" ++ title (movie rental) ++ "\t" ++ show (charge rental)
>     in (result ++ [rentalReportLine], accAmount + chrg, accFRPts + pts)
>
>   charge :: Rental -> Double
>   charge (Rental m nDays) = case priceCode m of
>     Regular    -> 2.0 + (if nDays > 2 then (fromIntegral nDays - 2) * 1.5 else 0)
>     NewRelease -> fromIntegral nDays * 3.0
>     Childrens  -> 1.5 + (if nDays > 3 then (fromIntegral nDays - 3) * 1.5 else 0)
>
>   frequentRenterPoints :: Rental -> Int
>   frequentRenterPoints (Rental (Movie _ NewRelease) nDays) | nDays > 1 = 2
>   frequentRenterPoints _ = 1

<small>The `Data.List.intercalate` function is simply what most other languages call `join` on a list of strings. The `unlines` function is like `intercalate "\n"` except it also adds a newline at the end.</small>

The `statement` function is the meat of the original example, and its translation required the biggest departure from its Ruby counterpart. The Ruby version begins by initializing a few local accumulator variables which are added to or appended to throughout the method body. In Haskell, we don't have assignment operators, because our variables aren't references, they're immutable values (this is Haskell's purity). Instead, threading accumulator state through a computation is accomplished by folding over a list. The helper function `f` defines how to add or append to our accumulator values as we fold over the list of the customer's rentals.

It would have been arguably easier to build up a statement with a few maps instead of a single fold, but that would have left us with even less to refactor.

We also have `charge` and `frequentRenterPoints` defined in `statement`'s local scope inside a `where` clause. In Haskell it is easy and natural to define local helper functions like this without worrying about polluting any broader namespace. None of these helper functions or intermediate values are in any way visible outside the scope of `statement`, and we haven't done any preemptive modularization. We of course could have put the definitions of `charge` and `frequentRenterPoints` in the `let` bindings of the `f` helper, where they are used, but in either case the pattern matching and guards would have worked and looked almost exactly the same.

Comments on the Starting Program
--------------------------------

We anticipate a couple of upcoming changes to which this program will need to adapt. The first is that the plaintext `statement` will need an HTML-generating counterpart. The second is that the `MovieType` system for classifying movies will change in an unknown way, and the formula for calculating charges for each `MovieType` will need to change with it.

The First Step in Refactoring
-----------------------------

Here, the authors say (paraphrased) that an efficient refactoring session will need to be supported by solid tests, so that we find out quickly if we introduce regressions. He doesn't give examples of the tests, but I will note here that the Haskell translation has *barely any* testable surface area that isn't already covered by the type system.

That is to say, expressive, statically checked types get us the same fast regression feedback during a refactoring session that we rely on tests for in Ruby. Moreover, we get the benefit with none of the investment required by hand-written tests, we are guaranteed full coverage, and most often we can display type errors directly in our editor *at the error site* instead of *at the broken test*.

Decomposing and Redistributing the Statement ~~Method~~ Function
----------------------------------------------------------------

The authors' first goal is to pull out the section of `statement` which handles calculating the amount to charge for each rental. The session proceeds in several stages. First, a preface is given regarding how to analyze the surrounding code to ensure we don't affect what remains when we extract a chunk of it. This is followed by the actual extraction into a method in the `Customer` class, and then by renaming a now-local variable so that it makes more sense in its new context. Finally, the new method is moved to its natural home in the `Rental` class, with the call site in `statement` updated to reflect its new location.

Eliding several intermediate steps, we end up with this Ruby.

```ruby
# in Rental class
  def charge
    result = 0
    case movie.price_code
    when Movie::REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when Movie::NEW_RELEASE
      result += days_rented * 3
    when Movie::CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end

# in Customer class
  def statement
    total_amount, frequent_renter_points = 0, 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      this_amount = element.charge
      # ^^^^ changed here ^^^^^^^^

      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      if element.movie.price_code == Movie.NEW_RELEASE &&
               element.days_rented > 1
          frequent_renter_points += 1
      end

      # show figures for this rental
      result += "\t" + each.movie.title + "\t" + this_amount.to_s + "\n"
      total_amount += this_amount
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
```

> charge :: Rental -> Double
> charge (Rental m nDays) = case priceCode m of
>   Regular    -> 2.0 + (if nDays > 2 then (fromIntegral nDays - 2) * 1.5 else 0)
>   NewRelease -> fromIntegral nDays * 3.0
>   Childrens  -> 1.5 + (if nDays > 3 then (fromIntegral nDays - 3) * 1.5 else 0)

In our Haskell example, we can simply unindent the `charge` helper so that it gets raised from the `statement` local scope into the `Refactoring` module scope, and move it to above or below the `statement` definition. If we wanted, we could rename `charge` to something else, or move it to a new file. Note that we would see a compiler error for any of these changes if we moved or renamed this function without updating its call sites. Also note that in all cases _its definition wouldn't need to change_, since it would have been less convenient to write it any other way in the first place.

The authors discuss a couple of concerns that are simply non-issues in Haskell. We _can't_ give a different local name to this function's `Rental` argument (which was a refactoring step in the Ruby example), since we never gave it a name! We only pattern matched on its contents. We also _can't_ worry about whether to make it a method on `Customer` or on `Rental`, since data types aren't namespaces like classes are, and Haskell functions don't have a magic `self` argument to worry about like OO instance methods. Our `charge` function is simply a pure function in our module.

Extracting Frequent Renter Points
---------------------------------

The authors perform a similar extraction on the section of `statement` that deals with frequent renter points. The authors elide these steps to a single operation, so we can assume the same steps were taken as in the previous section which dealt with extracting the `charge` computation out of `statement`.

```ruby
# in Customer class
  def statement
    total_amount, frequent_renter_points = 0, 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points
      # ^^^^^ changed here ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

      # show figures for this rental
      result += "\t" + each.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end

# in Rental class
  def frequent_renter_points
    (movie.price_code == Movie.NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
```

> frequentRenterPoints :: Rental -> Int
> frequentRenterPoints (Rental (Movie _ NewRelease) nDays) | nDays > 1 = 2
> frequentRenterPoints _ = 1

Again, this is a simple change in the Haskell example. We unindent `frequentRenterPoints` to bring it out into module scope, and the definition of the function needs no modification.

Removing Temps
--------------

For the sake of removing the accumulator variables used in computing the aggregate metrics over all rentals for a Customer, the authors pull `total_amount` and `frequent_renter_points` into their own `Customer` methods.

```ruby
class Customer
  def statement
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + each.movie.title + "\t" + element.charge.to_s + "\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{total_frequent_renter_points} frequent renter points" result
  end

  private

  def total_charge
    @rentals.inject(0) { |sum, rental| sum + rental.charge }
  end

  def total_frequent_renter_points
    @rentals.inject(0) { |sum, rental| sum + rental.frequent_renter_points }
  end
end
```

> totalCharge :: Customer -> Double
> totalCharge cust = sum $ map charge $ rentals cust
>
> totalFrequentRenterPoints :: Customer -> Int
> totalFrequentRenterPoints = sum . map frequentRenterPoints . rentals

The analogous definitions in Haskell are just as short as the rather concise Ruby definitions. They get slightly shorter if we define them by composing functions instead of fully applying them, as in `totalFrequentRenterPoints`.

And with that, we can rewrite our `statement` function to make use of our refactorings.

> statement' :: Customer -> String
> statement' c = unlines
>     [ "Rental record for " ++ name c
>     , intercalate "\n" rentalReportLines
>     , "Amount owed is " ++ show (totalCharge c)
>     , "You earned " ++ show (totalFrequentRenterPoints c) ++ " frequent renter points"
>     ]
>   where
>   rentalReportLines = flip map (rentals c) $ \rental ->
>     "\t" ++ title (movie rental) ++ "\t" ++ show (charge rental)

Finally, we can do what we set out to and write our html statement.

```ruby
# in Customer class
  def html_statement
    result = "<h1>Rentals for <em>#{@name}</em></h1><p>\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + each.movie.title + ": " + element.charge.to_s + "<br>\n"
    end
    # add footer lines
    result += "<p>You owe <em>#{total_charge}</em><p>\n"
    result += "On this rental you earned " +
           "<em>#{total_frequent_renter_points}</em> " +
           "frequent renter points<p>"
    result
  end
```

> htmlStatement :: Customer -> String
> htmlStatement c = unlines
>     [ "<h1>Rentals for <em>" ++ name c ++ "</em></h1><p>"
>     , intercalate "\n" rentalReportLines
>     , "<p>You owe <em>" ++ show (totalCharge c) ++ "</em><p>"
>     , "On this rental you earned <em>" ++ show (totalFrequentRenterPoints c) ++ " frequent renter points<p>"]
>   where
>   rentalReportLines = flip map (rentals c) $ \rental ->
>     "\t" ++ title (movie rental) ++ ": " ++ show (charge rental) ++ "<br>"

Note also that at this point in the book, several UML class diagrams had been given to keep the reader oriented among all the code changes at play. In Haskell, we almost always have type signatures to serve exactly that purpose, and when we don't, we can still interrogate the compiler for the type of any value it knows about, and often do so without leaving our text editor!

Replacing the Conditional Logic on Price Code with Polymorphism
---------------------------------------------------------------

At this point, the authors decide treating a group of constants as together forming an enum so that we can switch over them is a Bad Idea™. It is decidedly slightly less bad if that case statement only needs to be defined in one place. This naturally requires a refactor to move both the `charge` method and the `frequent_renter_points` from the `Rental` class to the `Movie` class, which is where the constants are defined.

Moreover, the prescribed solution to this dilemma is to _encode the enum in a class hierarchy instead of in constants_. The ensuing refactor is given the most detailed play-by-play of any in the chapter, and involves no fewer than

- 1 custom setter
- 3 bespoke classes
- 1 mixin providing a default method implementation for 2/3 of the classes
- 5 methods in total, split across those classes and mixins

to support the `charge` and `frequentRenterPoints` in a way that avoids using constants as enums. This is, in my opinion, _a nightmare_. Though some Ruby programmers may disagree that the original example is the best approach for the problem given, it's tough to argue that the approach outlined here is _the most object-oriented_, and that all too many programmers thereby consider it to be _the most praiseworthy_.

After lots of incremental changes, the Ruby comes out looking like this.

```ruby
module DefaultPrice
  def frequent_renter_points(days_rented)
    1
  end
end

class RegularPrice
  include DefaultPrice
  def charge(days_rented)
    result = 2
    result += (days_rented - 2) * 1.5 if days_rented > 2
    result
  end
end

class NewReleasePrice
  def charge(days_rented)
    days_rented * 3
  end
  def frequent_renter_points(days_rented)
    days_rented > 1 ? 2 : 1
  end
end

class ChildrensPrice
  include DefaultPrice
  def charge(days_rented)
    result = 1.5
    result += (days_rented - 3) * 1.5 if days_rented > 3
    result
  end
end

# then, in Movie class
  def charge(days_rented)
    @price.charge(days_rented)
  end
  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
```

The Haskell examples already given have all their bases covered here, and then some. They don't need to change, _at all_, for 2 reasons. First, Haskell has fantastic support for user-defined data types. Defining an enum is dead simple, and defining fancier algebraic data types (not shown here) is not much more difficult. Second, designing and organizing your functions and data types are completely separate concerns from organizing your namespaces. This is in stark contrast with Ruby and most other OO languages, where both are concerns are painfully intertwined, as exhibited here.

I want to pause and note, again, that the primary motivation for this whole section of changes, which take no fewer than _16 pages_ in the book, boils down to a lack of enums or sum types in Ruby. In Haskell, we can define what kinds of movies we know about, in a single place, as a data type.

```haskell
data MovieType = Regular | NewRelease | Childrens
```

The compiler can then detect when we fail to consider one of these possible values, or we try to treat one as something it's not, or even we do something silly like spell one of their names wrong. In Ruby, the best we can do is give some special names to what are really just a handful of integers, and then hope our tests are good enough to catch when we make one of those mistakes. Unsurprisingly, this makes code feel pretty brittle.
