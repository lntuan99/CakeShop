//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace CakeShop
{
    using System;
    using System.Collections.Generic;
    
    public partial class InvoiceDetail
    {
        public int ID_Invoice { get; set; }
        public int Ordinal_Number { get; set; }
        public Nullable<int> ID_Cake { get; set; }
        public Nullable<int> Quantity { get; set; }
    
        public virtual Cake Cake { get; set; }
        public virtual Invoice Invoice { get; set; }
    }
}
